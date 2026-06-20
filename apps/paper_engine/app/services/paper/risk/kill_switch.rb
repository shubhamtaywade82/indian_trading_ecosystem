module Paper
  module Risk
    class KillSwitch
      def self.evaluate(account_id:, strategy_id:)
        # Strategy level
        if strategy_id
          strat_prof = PaperRiskProfile.find_by(account_id: account_id, strategy_id: strategy_id)
          if strat_prof&.status == 'HALTED'
            return { success: false, reason: "KILL_SWITCH: Strategy " + strategy_id.to_s + " is halted." }
          end
        end

        # Portfolio level
        port_prof = PaperRiskProfile.find_by(account_id: account_id, strategy_id: nil)
        if port_prof&.status == 'HALTED'
          return { success: false, reason: "KILL_SWITCH: Portfolio is halted." }
        end

        { success: true }
      end

      def self.halt!(account_id:, strategy_id: nil, reason:)
        prof = PaperRiskProfile.find_or_create_by!(account_id: account_id, strategy_id: strategy_id)
        prof.update!(status: 'HALTED')
      end
    end
  end
end
