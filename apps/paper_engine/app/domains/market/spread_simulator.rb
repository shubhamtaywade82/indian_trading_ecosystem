module Market
  class SpreadSimulator
    def self.simulate(runtime, ltp)
      model = runtime.spread_model || 'HISTORICAL'
      
      case model
      when 'HISTORICAL'
        # Would use historical spread from tick data
        # For mock: fallback to a default spread
        0.05
      when 'VOLATILITY_BASED'
        # e.g., higher spread during volatile sessions
        ltp * 0.001
      else
        0.05
      end
    end
  end
end
