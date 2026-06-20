require 'rails_helper'

RSpec.describe "Core Trading Loop — Full Pipeline (Phase 9+10)", type: :model do
  # 30 candles: first 22 flat at 100, then ramp up to 130 in 8 steps.
  # The short EMA (9) will rise much faster than the long EMA (21), guaranteeing a cross.
  def build_candles_with_golden_cross
    flat  = Array.new(22, 100.0)
    ramp  = (1..8).map { |i| 100.0 + (i * 3.75) } # 103.75 → 130.0
    (flat + ramp).map { |p| { close: p } }
  end

  describe "EmaXoverMomentum strategy" do
    it "generates a BUY signal on golden cross" do
      strategy = Strategy::EmaXoverMomentum.new(short_period: 9, long_period: 21)
      snapshot = { 'RELIANCE' => build_candles_with_golden_cross }

      signals = strategy.evaluate(snapshot, {})

      expect(signals.length).to eq(1)
      expect(signals.first.instrument_id).to eq('RELIANCE')
      expect(signals.first.buy?).to be true
      expect(signals.first.confidence).to be > 0
    end

    it "returns no signal when no crossover" do
      strategy = Strategy::EmaXoverMomentum.new(short_period: 9, long_period: 21)
      flat_prices = Array.new(25, 100.0)
      snapshot = { 'INFY' => flat_prices.map { |p| { close: p } } }

      signals = strategy.evaluate(snapshot, {})
      expect(signals).to be_empty
    end
  end

  describe "Risk::PreTradeGuard" do
    let(:mandate) { Portfolio::Mandate.new(max_weight_per_asset: 0.10, min_cash_buffer_pct: 0.05) }
    let(:portfolio_state) do
      {
        total_value: 1_000_000.0,
        cash: 500_000.0,
        positions: {
          'RELIANCE' => { qty: 100, value: 250_000.0 }
        }
      }
    end

    it "blocks an order that breaches mandate max weight" do
      # 150k order on 1M portfolio = 15%, mandate max is 10%
      order = { instrument_id: 'RELIANCE', side: 'buy', qty: 60, price: 2500 }
      result = Risk::PreTradeGuard.check(order: order, portfolio_state: portfolio_state, mandate: mandate)
      expect(result[:pass]).to be false
      expect(result[:code]).to eq('MANDATE_WEIGHT_BREACH')
    end

    it "blocks a fat-finger order (>25% of portfolio in one shot)" do
      order = { instrument_id: 'RELIANCE', side: 'buy', qty: 100, price: 3000 } # 300k / 1M = 30%
      result = Risk::PreTradeGuard.check(order: order, portfolio_state: portfolio_state, mandate: mandate)
      expect(result[:pass]).to be false
      expect(result[:code]).to eq('NOTIONAL_TOO_LARGE')
    end

    it "allows a compliant order" do
      order = { instrument_id: 'TCS', side: 'buy', qty: 10, price: 3500 } # 35k / 1M = 3.5%
      result = Risk::PreTradeGuard.check(order: order, portfolio_state: portfolio_state, mandate: mandate)
      expect(result[:pass]).to be true
    end
  end

  describe "ExecutionGateway with BacktestAdapter" do
    it "routes to BacktestAdapter and accumulates orders in-memory" do
      config = double('RuntimeConfig', mode: 'backtest', broker: nil, paper_account_id: nil)

      gateway = Execution::Gateway.new(config)

      gateway.place_order({ instrument_id: 'RELIANCE', side: 'buy', qty: 100, price: 2500 })
      gateway.place_order({ instrument_id: 'INFY', side: 'buy', qty: 200, price: 1000 })

      orders = gateway.orders
      expect(orders.length).to eq(2)
      expect(orders.first[:instrument_id]).to eq('RELIANCE')
    end

    it "positions are correctly derived from filled orders" do
      config = double('RuntimeConfig', mode: 'backtest', broker: nil, paper_account_id: nil)
      gateway = Execution::Gateway.new(config)

      gateway.place_order({ instrument_id: 'RELIANCE', side: 'buy', qty: 100, price: 2500 })
      gateway.place_order({ instrument_id: 'RELIANCE', side: 'sell', qty: 30, price: 2600 })

      positions = gateway.positions
      expect(positions['RELIANCE']).to eq(70)
    end
  end

  describe "Full TradingLoop end-to-end (backtest mode)" do
    it "generates signals, allocates capital, and submits orders via gateway" do
      config = double('RuntimeConfig',
        mode: 'backtest',
        broker: nil,
        paper_account_id: nil
      )

      mandate = Portfolio::Mandate.new(max_weight_per_asset: 0.50, min_cash_buffer_pct: 0.05)
      strategy = Strategy::EmaXoverMomentum.new(short_period: 9, long_period: 21)

      loop = Core::TradingLoop.new(config, mandate, [strategy])

      market_data = {
        'RELIANCE' => build_candles_with_golden_cross,
        'INFY'     => Array.new(25, { close: 100.0 }) # flat, no signal
      }

      expect { loop.run!(market_data) }.not_to raise_error

      # Gateway is internal, but we can verify via the gateway's adapter
      gateway = loop.instance_variable_get(:@gateway)
      adapter = gateway.instance_variable_get(:@adapter)

      expect(adapter.submitted_orders.length).to be >= 1
      submitted = adapter.submitted_orders.find { |o| o[:instrument_id] == 'RELIANCE' }
      expect(submitted).not_to be_nil
      expect(submitted[:side]).to eq('buy')
    end
  end
end
