module BrokerProfiles
  class MarginEmulator
    def self.calculate_margin(runtime, account, params)
      profile = runtime.broker_profile
      base_margin = Broker::MarginCalculator.calculate(params)

      return base_margin unless profile

      rules = profile.rules

      case params[:product_type]
      when 'MIS'
        multiplier = rules['margin_multiplier_mis'] || 1.0
        # If multiplier is 5.0, margin is base_margin / 5.0
        base_margin / multiplier.to_f
      else
        base_margin
      end
    end
  end
end
