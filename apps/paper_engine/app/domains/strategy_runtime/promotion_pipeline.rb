module StrategyRuntime
  class PromotionPipeline
    def self.promote(strategy)
      validation = ValidationPipeline.validate(strategy)
      if validation[:success]
        strategy.update!(status: 'LIVE_ENABLED')
        
        Events::DomainEvent.create!(
          runtime_id: strategy.runtime_id,
          event_type: 'strategy.promoted',
          payload: { strategy_id: strategy.id, status: 'LIVE_ENABLED' },
          occurred_at: Time.current
        )
        
        { success: true }
      else
        { success: false, reason: validation[:reason] }
      end
    end
  end
end
