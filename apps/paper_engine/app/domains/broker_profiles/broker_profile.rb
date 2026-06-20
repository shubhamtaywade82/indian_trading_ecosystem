module BrokerProfiles
  class BrokerProfile < ApplicationRecord
    self.table_name = "broker_profiles"
    
    # rules JSON structure expected:
    # {
    #   "allow_intraday_short": true,
    #   "freeze_qty": 1800,
    #   "max_order_value": 10000000,
    #   "supports_gtt": true,
    #   "supports_amo": true,
    #   "supported_products": ["CNC", "MIS", "NRML"],
    #   "margin_multiplier_mis": 5.0,
    #   "brokerage_plan": "FLAT_20"
    # }
  end
end
