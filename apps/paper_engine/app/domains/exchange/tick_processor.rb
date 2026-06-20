module Exchange
  class TickProcessor
    def self.process(runtime_id:, symbol:, tick:)
      book = OrderBook.for(runtime_id, symbol)
      book.update_liquidity(
        ltp: tick[:ltp],
        bid_price: tick[:bid] || tick[:bid_price],
        bid_qty: tick[:bid_qty] || 999999,
        ask_price: tick[:ask] || tick[:ask_price],
        ask_qty: tick[:ask_qty] || 999999
      )

      # Trigger matching for rested orders against the new book
      MatchingEngine.process_rested_orders(runtime_id, symbol)
    end
  end
end
