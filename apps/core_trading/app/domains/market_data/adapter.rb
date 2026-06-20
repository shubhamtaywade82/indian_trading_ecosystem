module MarketData
  class Adapter
    def self.fetch_snapshot(symbol)
      raise NotImplementedError, "\#{self.class} must implement fetch_snapshot"
    end

    def self.subscribe(symbols, &block)
      raise NotImplementedError, "\#{self.class} must implement subscribe"
    end

    def self.fetch_historical(symbol, timeframe, from, to)
      raise NotImplementedError, "\#{self.class} must implement fetch_historical"
    end
  end
end
