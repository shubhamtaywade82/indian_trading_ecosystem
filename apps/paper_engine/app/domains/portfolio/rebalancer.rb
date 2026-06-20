module Portfolio
  class Rebalancer
    def self.rebalance(allocation, runtime, account)
      target_weights = allocation.target_weights
      # Simplified logic: 
      # Diff target vs actual weights, and generate BUY/SELL orders.
      # For now, just a stub that emits an event.

      Events::DomainEvent.create!(
        runtime_id: runtime.id,
        event_type: 'rebalance.executed',
        payload: { allocation_id: allocation.id, targets: target_weights },
        occurred_at: Time.current
      )

      { success: true }
    end
  end
end
