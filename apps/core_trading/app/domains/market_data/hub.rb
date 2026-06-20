module MarketData
  class Hub
    def self.adapter_for(source_name)
      case source_name.to_s.downcase
      when 'dhan'
        DhanAdapter
      when 'replay', 'paper'
        ReplayAdapter
      else
        raise "Unknown market data source: \#{source_name}"
      end
    end

    def self.fetch_snapshot(symbol, source:)
      adapter = adapter_for(source)
      adapter.fetch_snapshot(symbol)
    end

    def self.fetch_historical(symbol, timeframe, from, to, source:)
      adapter = adapter_for(source)
      adapter.fetch_historical(symbol, timeframe, from, to)
    end
  end
end
