module Exchange
  class OrderBook
    @books = {}
    @mutex = Mutex.new

    class << self
      def for(runtime_id, symbol)
        @mutex.synchronize do
          @books[runtime_id] ||= {}
          @books[runtime_id][symbol] ||= new(runtime_id, symbol)
        end
      end

      def clear_all
        @mutex.synchronize { @books.clear }
      end
    end

    attr_reader :runtime_id, :symbol, :bid_price, :bid_qty, :ask_price, :ask_qty, :ltp

    def initialize(runtime_id, symbol)
      @runtime_id = runtime_id
      @symbol = symbol
      @bid_price = 0.0
      @bid_qty = 0
      @ask_price = 0.0
      @ask_qty = 0
      @ltp = 0.0
    end

    def update_liquidity(ltp:, bid_price:, bid_qty:, ask_price:, ask_qty:)
      @ltp = ltp
      @bid_price = bid_price
      @bid_qty = bid_qty
      @ask_price = ask_price
      @ask_qty = ask_qty
    end

    def consume_ask_qty(qty)
      filled = [qty, @ask_qty].min
      @ask_qty -= filled
      filled
    end

    def consume_bid_qty(qty)
      filled = [qty, @bid_qty].min
      @bid_qty -= filled
      filled
    end
  end
end
