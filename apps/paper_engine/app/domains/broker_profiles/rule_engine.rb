module BrokerProfiles
  class RuleEngine
    def self.evaluate(runtime, account, params)
      profile = runtime.broker_profile || BrokerProfile.find_by(name: 'paper-generic')
      return { success: true, profile: profile } unless profile

      rules = profile.rules

      # 1. Product Emulator check
      unless rules['supported_products']&.include?(params[:product_type])
        return { success: false, reason: "PRODUCT_NOT_SUPPORTED_BY_BROKER" }
      end

      # 2. Max value check
      if params[:price].to_f > 0 && rules['max_order_value']
        value = params[:quantity].to_i * params[:price].to_f
        if value > rules['max_order_value'].to_f
          return { success: false, reason: "MAX_ORDER_VALUE_EXCEEDED" }
        end
      end

      # 3. Freeze quantity emulator (we don't auto-split here yet, just validate or mark for split)
      # ExecutionGateway handles auto-splitting, so we do not reject here.

      { success: true, profile: profile }
    end
  end
end
