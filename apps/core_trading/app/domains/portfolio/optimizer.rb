module Portfolio
  class Optimizer
    def self.optimize(signals, current_portfolio, mandate)
      # Takes raw signals and produces target target_weights (e.g. { 'RELIANCE' => 0.05, 'INFY' => 0.02 })
      # In reality, this runs Mean-Variance Optimization, Black-Litterman, or Risk Parity.
      
      target_weights = {}
      total_confidence = signals.sum(&:confidence)
      return target_weights if total_confidence == 0

      # Naive conviction-weighted allocation
      signals.each do |signal|
        # Skip shorts if mandate doesn't allow, but let's assume long-only for now
        next unless signal.buy?

        weight = signal.confidence / total_confidence.to_f
        # Cap at mandate max weight
        weight = [weight, mandate.max_weight_per_asset].min
        
        target_weights[signal.instrument_id] ||= 0
        target_weights[signal.instrument_id] += weight
      end

      # Normalize again if sum > (1.0 - cash_buffer)
      max_investable = 1.0 - mandate.min_cash_buffer_pct
      sum_weights = target_weights.values.sum
      
      if sum_weights > max_investable
        scale = max_investable / sum_weights
        target_weights.transform_values! { |w| w * scale }
      end

      target_weights
    end
  end
end
