module Core
  # The TradingLoop is the top-level orchestrator.
  # It is the only place that wires Strategy → Portfolio → Risk → Execution.
  # Nothing else should know about this pipeline.
  #
  # Invocation:
  #   config  = Core::RuntimeConfig.find_by(name: 'main')
  #   mandate = Portfolio::Mandate.new(max_weight_per_asset: 0.10)
  #   strategies = [Strategy::EmaXoverMomentum.new(short_period: 9, long_period: 21)]
  #
  #   Core::TradingLoop.new(config, mandate, strategies).run!(market_data_snapshot)
  #
  class TradingLoop
    def initialize(runtime_config, mandate, strategies)
      @runtime_config = runtime_config
      @mandate        = mandate
      @strategies     = strategies
      @gateway        = Execution::Gateway.new(runtime_config)
    end

    def run!(market_data_snapshot)
      # 1. Fetch current portfolio state from execution layer
      portfolio_state = fetch_portfolio_state

      # 2. Generate signals from all strategies
      signal_generator = Strategy::SignalGenerator.new(@strategies)
      signals          = signal_generator.run!(market_data_snapshot, portfolio_state)

      Rails.logger.info("[TradingLoop] #{signals.length} signals generated")
      return if signals.empty?

      # 3. Optimise signals into target allocation weights
      target_weights = Portfolio::Optimizer.optimize(signals, portfolio_state[:positions], @mandate)

      # 4. Convert weights into absolute quantities
      current_prices = extract_prices(market_data_snapshot)
      target_positions = Portfolio::CapitalAllocationEngine.allocate(
        target_weights,
        portfolio_state[:total_value],
        current_prices
      )

      # 5. Generate rebalancing orders (sells before buys)
      current_positions = portfolio_state[:positions].transform_values { |v| v[:qty] }
      orders = Portfolio::ConstructionEngine.generate_orders(target_positions, current_positions, @mandate)

      Rails.logger.info("[TradingLoop] #{orders.length} rebalancing orders constructed")

      # 6. Pre-trade risk check and submit each order
      orders.each do |order_payload|
        order_payload[:price] = current_prices[order_payload[:instrument_id]] || 0

        risk_result = Risk::PreTradeGuard.check(
          order: order_payload,
          portfolio_state: portfolio_state,
          mandate: @mandate
        )

        unless risk_result[:pass]
          Rails.logger.warn("[TradingLoop] Order blocked by PreTradeGuard: #{risk_result[:reason]}")
          next
        end

        result = @gateway.place_order(order_payload)
        Rails.logger.info("[TradingLoop] Order submitted: #{result.inspect}")
      end
    end

    private

    def fetch_portfolio_state
      funds_data    = @gateway.funds
      positions_raw = @gateway.positions

      available_cash  = funds_data&.fetch(:available, 0).to_f
      positions_value = positions_raw.sum { |_, v| v.is_a?(Hash) ? v.fetch(:value, 0).to_f : 0 }

      {
        total_value: available_cash + positions_value,
        cash: available_cash,
        positions: positions_raw || {}
      }
    end

    def extract_prices(market_data_snapshot)
      market_data_snapshot.transform_values { |candles| candles.last[:close] }
    end
  end
end
