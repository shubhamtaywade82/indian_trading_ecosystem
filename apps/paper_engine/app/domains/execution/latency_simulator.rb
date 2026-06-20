module Execution
  class LatencySimulator
    def self.simulate(runtime)
      model = runtime.latency_model || 'NONE'

      case model
      when 'NONE'
        0
      when 'FIXED'
        0.05 # 50ms
      when 'BROKER_PROFILE'
        # E.g. Dhan is 50ms, Kite is 35ms.
        0.035
      when 'NORMAL_DISTRIBUTION'
        # Random between 20ms and 100ms
        rand(0.02..0.1)
      else
        0
      end
    end
  end
end
