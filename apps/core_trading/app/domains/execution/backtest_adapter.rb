module Execution
  # Stub adapter for backtesting mode.
  # Records all "sent" orders in memory for analysis without touching any engine.
  class BacktestAdapter < Adapter
    attr_reader :submitted_orders

    def initialize(runtime_config)
      @runtime_config = runtime_config
      @submitted_orders = []
      @next_id = 1
    end

    def place_order(payload)
      order = payload.merge(id: next_id!, status: 'FILLED', filled_at: Time.current)
      @submitted_orders << order
      { success: true, order_id: order[:id], status: 'FILLED' }
    end

    def cancel_order(order_id)
      order = @submitted_orders.find { |o| o[:id] == order_id }
      order&.merge!(status: 'CANCELLED')
      { success: true }
    end

    def positions
      # Derive net positions from submitted orders
      pos = {}
      @submitted_orders.each do |o|
        next unless o[:status] == 'FILLED'
        pos[o[:instrument_id]] ||= 0
        qty = o[:side] == 'buy' ? o[:qty] : -o[:qty]
        pos[o[:instrument_id]] += qty
      end
      pos
    end

    def holdings; {}; end
    def funds; { available: Float::INFINITY }; end
    def orders; @submitted_orders; end
    def trades; @submitted_orders.select { |o| o[:status] == 'FILLED' }; end

    private

    def next_id!
      id = @next_id
      @next_id += 1
      id
    end
  end
end
