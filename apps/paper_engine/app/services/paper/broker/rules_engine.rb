module Paper
  module Broker
    class RulesEngine
      def self.evaluate(account:, payload:)
        broker_name = ENV['BROKER_PROFILE'] || 'kite'
        
        profile = BrokerProfile.find_by(broker_name: broker_name)
        
        # If no strict profile, allow by default
        return { success: true } unless profile

        instrument = payload[:instrument_id]
        qty = payload[:qty]
        
        if profile.max_order_qty && qty > profile.max_order_qty
          return error_response(profile, 'MAX_QTY_EXCEEDED', "Maximum order quantity is \#{profile.max_order_qty}")
        end

        if profile.block_penny_stocks && penny_stock?(instrument)
          return error_response(profile, 'INSTRUMENT_RESTRICTED', "Penny stocks are blocked by this broker")
        end

        if profile.restrict_illiquid_options && illiquid_option?(instrument)
          return error_response(profile, 'ILLIQUID_INSTRUMENT', "Trading in illiquid options is restricted")
        end

        { success: true }
      end

      def self.error_response(profile, code, message)
        case profile.error_format
        when 'kite'
          { success: false, reason: "InputException: \#{message}" }
        when 'dhan'
          { success: false, reason: "RS-\#{code}: \#{message}" }
        else
          { success: false, reason: "\#{code}: \#{message}" }
        end
      end

      # Stub implementations for simulation
      def self.penny_stock?(instrument)
        # In real system, this checks price < 10 or market cap. 
        # For simulation, just string match for test capability
        instrument.include?('PENNY')
      end

      def self.illiquid_option?(instrument)
        instrument.include?('FAR_OTM')
      end
    end
  end
end
