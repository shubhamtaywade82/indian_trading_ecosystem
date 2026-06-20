module Paper
  module Execution
    class LatencySimulator
      # In a real event-driven system, latency means we don't process the order immediately.
      # We queue it.
      def self.simulate(order:, base_ms: 50, jitter_ms: 20)
        return 0 unless ENV['SIMULATE_LATENCY'] == 'true' || order.account.mode == 'paper_latency'
        
        # Calculate random latency based on normal distribution approximation or uniform
        latency_ms = base_ms + rand(-jitter_ms..jitter_ms)
        latency_ms = 0 if latency_ms < 0
        
        # In a real concurrent system, we'd use ActiveJob:
        # MatchingEngineJob.set(wait: latency_ms.milliseconds).perform_later(order.id)
        # For our MVP synchronous tests, we might just sleep, or return the ms for the caller to sleep.
        # We will return the latency in ms. The caller can decide to queue or sleep.
        latency_ms
      end
    end
  end
end
