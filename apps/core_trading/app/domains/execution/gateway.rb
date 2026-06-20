module Execution
  # The ExecutionGateway is the ONLY way Core Trading communicates with any broker.
  # It routes to PaperEngineAdapter or a real broker adapter depending on RuntimeConfig#mode.
  # Core never calls DhanHQ or PaperEngine directly.
  class Gateway
    def initialize(runtime_config)
      @runtime_config = runtime_config
      @adapter = resolve_adapter
    end

    def place_order(payload)
      log(:place_order, payload)
      @adapter.place_order(payload)
    end

    def cancel_order(order_id)
      log(:cancel_order, { order_id: order_id })
      @adapter.cancel_order(order_id)
    end

    def positions
      @adapter.positions
    end

    def holdings
      @adapter.holdings
    end

    def funds
      @adapter.funds
    end

    def orders
      @adapter.orders
    end

    private

    def resolve_adapter
      case @runtime_config.mode
      when 'paper'
        Execution::PaperEngineAdapter.new(@runtime_config)
      when 'live'
        resolve_live_adapter
      when 'backtest'
        Execution::BacktestAdapter.new(@runtime_config)
      else
        raise ArgumentError, "Unknown execution mode: #{@runtime_config.mode}"
      end
    end

    def resolve_live_adapter
      broker = @runtime_config.broker || raise(ArgumentError, "RuntimeConfig#broker required for live mode")
      case broker
      when 'dhan'
        Execution::DhanAdapter.new(@runtime_config)
      when 'kite'
        Execution::KiteAdapter.new(@runtime_config)
      else
        raise ArgumentError, "Unknown broker: #{broker}"
      end
    end

    def log(action, payload)
      Rails.logger.info("[ExecutionGateway] action=#{action} mode=#{@runtime_config.mode} payload=#{payload.inspect}")
    end
  end
end
