module Broker
  class RMSEngine
    def self.evaluate(runtime, account, params)
      # 1. Product Rules
      rules = ProductRules.validate(params)
      return { success: false, reason: 'PRODUCT_RULES_BREACH' } unless rules[:success]

      # 2. Exposure Limits
      exposure = ExposureEngine.validate(account, params)
      return { success: false, reason: 'EXPOSURE_BREACH' } unless exposure[:success]

      # 3. Margin Requirement
      required_margin = BrokerProfiles::MarginEmulator.calculate_margin(runtime, account, params)

      margin_account = MarginAccount.find_or_initialize_by(runtime: runtime, account: account)
      
      if margin_account.available_margin < required_margin
        return { success: false, reason: 'INSUFFICIENT_FUNDS', required: required_margin, available: margin_account.available_margin }
      end

      # Block Margin
      margin_account.with_lock do
        margin_account.available_margin -= required_margin
        margin_account.blocked_margin += required_margin
        margin_account.save!
      end

      Events::DomainEvent.create!(
        runtime: runtime,
        event_type: 'margin.blocked',
        payload: { amount: required_margin },
        occurred_at: Time.current
      )

      { success: true, blocked_amount: required_margin }
    end

    def self.release_margin(runtime, account, amount)
      margin_account = MarginAccount.find_by(runtime: runtime, account: account)
      return unless margin_account

      margin_account.with_lock do
        margin_account.blocked_margin -= amount
        margin_account.available_margin += amount
        margin_account.save!
      end

      Events::DomainEvent.create!(
        runtime: runtime,
        event_type: 'margin.released',
        payload: { amount: amount },
        occurred_at: Time.current
      )
    end
  end
end
