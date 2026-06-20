module Core
  class InstrumentMaster
    def self.find_by_symbol(symbol, exchange: 'NSE')
      Instrument.find_by(symbol: symbol, exchange: exchange)
    end

    def self.find_by_alias(alias_name, provider:)
      instrument_alias = InstrumentAlias.find_by(alias_name: alias_name, provider: provider)
      instrument_alias&.instrument
    end

    def self.search(query, limit: 10)
      Instrument.where("symbol ILIKE ? OR name ILIKE ?", "%\#{query}%", "%\#{query}%").limit(limit)
    end

    def self.options_for(underlying_symbol, expiry_date: nil)
      scope = OptionContract.where(underlying_symbol: underlying_symbol)
      scope = scope.where(expiry_date: expiry_date) if expiry_date
      scope.order(:strike_price)
    end

    def self.futures_for(underlying_symbol)
      FutureContract.where(underlying_symbol: underlying_symbol).order(:expiry_date)
    end
  end
end
