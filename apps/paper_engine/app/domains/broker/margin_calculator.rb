module Broker
  class MarginCalculator
    def self.calculate(params)
      # Mocking lookup logic
      segment = params[:segment] || 'equity'
      product_type = params[:product_type] || 'CNC'
      
      req = MarginRequirement.find_by(segment: segment, product_type: product_type, symbol: params[:symbol]) ||
            MarginRequirement.find_by(segment: segment, product_type: product_type, symbol: nil)
            
      req_pct = req ? req.cash_requirement_pct : 1.0
      req_pct = 0.2 if product_type == 'MIS'

      # Fallback price calculation
      price = params[:price] && params[:price] > 0 ? params[:price] : 1000.0 # Using a mock LTP if MARKET order without a real feed
      
      required_margin = params[:quantity].to_i * price * req_pct
      required_margin
    end
  end
end
