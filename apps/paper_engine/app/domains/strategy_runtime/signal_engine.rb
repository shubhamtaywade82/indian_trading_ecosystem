module StrategyRuntime
  class SignalEngine
    def self.process(signal)
      # 1. Validation
      # Check if symbol is in mandate allowed segments
      mandate = signal.investment_mandate
      unless mandate.allowed_segments.include?('all') || mandate.allowed_segments.include?(signal.symbol)
        signal.update!(status: 'REJECTED')
        return { success: false, reason: "SYMBOL_NOT_IN_MANDATE" }
      end

      # 2. Update status
      signal.update!(status: 'VALIDATED')

      # 3. Emit Event
      Events::DomainEvent.create!(
        runtime_id: signal.strategy.runtime_id,
        event_type: 'signal.validated',
        payload: { signal_id: signal.id, action: signal.action },
        occurred_at: Time.current
      )

      { success: true, signal: signal }
    end

    def self.approve(signal)
      signal.update!(status: 'APPROVED')
      
      Events::DomainEvent.create!(
        runtime_id: signal.strategy.runtime_id,
        event_type: 'signal.approved',
        payload: { signal_id: signal.id },
        occurred_at: Time.current
      )

      # In a real system, approval triggers the Rebalancer or ExecutionGateway
      { success: true }
    end
  end
end
