module Risk
  class KillSwitch
    def self.activate!(runtime_id, strategy_id, reason)
      if strategy_id
        strategy = Strategy.find_by(id: strategy_id)
        strategy.update!(status: 'STOPPED') if strategy
      else
        # Portfolio level
        Strategy.where(runtime_id: runtime_id).update_all(status: 'STOPPED')
      end

      Events::DomainEvent.create!(
        runtime_id: runtime_id,
        event_type: 'risk.kill_switch_activated',
        payload: { strategy_id: strategy_id, reason: reason },
        occurred_at: Time.current
      )
    end
  end
end
