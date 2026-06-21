module Paper
  module Broker
    class MarginCalculator
      def self.calculate(instrument_id:, product_type:, qty:, price:, side:, segment: nil)
        # Auto-detect segment from instrument symbol if not specified
        segment ||= if instrument_id.to_s.match?(/(CE|PE)\z/i)
                      'options'
                    elsif instrument_id.to_s.match?(/FUT/i)
                      'futures'
                    else
                      'equity'
                    end

        # Find requirement config or use conservative defaults
        req = MarginRequirement.find_by(symbol: instrument_id, product_type: product_type)
        
        # Default fallback requirements if no specific config exists
        span_pct = req&.span_margin_pct || default_span(product_type, segment)
        exposure_pct = req&.exposure_margin_pct || default_exposure(product_type, segment)
        cash_req_pct = req&.cash_requirement_pct || 1.0 # default to 100% cash equivalent needed
        
        total_margin_pct = (span_pct + exposure_pct) * cash_req_pct
        
        # We need a price. If order is Market and no price is passed, we'd theoretically need LTP.
        # For simulation RMS, if price is nil, we reject it earlier, or assume a high dummy price, or require price.
        # Let's assume price is provided (or a worst-case price is passed in).
        trade_value = qty * (price || 0)
        
        # Options buying requires full premium as margin
        if segment == 'options' && side == 'buy'
          return trade_value
        end
        
        # Basic calculation
        trade_value * total_margin_pct
      end
      
      def self.default_span(product_type, segment)
        case product_type
        when 'CNC' then 1.0   # 100% for delivery
        when 'MIS' then 0.20  # 20% for intraday equity
        when 'NRML' then 0.15 # 15% for futures carry
        else 1.0
        end
      end
      
      def self.default_exposure(product_type, segment)
        0.0 # Simplify default exposure
      end
    end
  end
end
