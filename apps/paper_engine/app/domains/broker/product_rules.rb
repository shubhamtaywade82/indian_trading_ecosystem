module Broker
  class ProductRules
    def self.validate(params)
      # Simulating simple rules
      if params[:product_type] == 'CNC' && params[:side] == 'SELL'
        # Would normally check if holdings exist
        # Let's say we allow it for now, or normally reject short sell in CNC
      end

      { success: true }
    end
  end
end
