module Portfolio
  class CapitalAllocationEngine
    # Convert percentage target weights into absolute quantities based on total capital
    def self.allocate(target_weights, total_capital, current_prices)
      # Guard: BacktestAdapter returns Infinity for funds. Use a sensible ceiling.
      total_capital = [total_capital.to_f, 100_000_000.0].min
      total_capital = 10_000_000.0 if total_capital <= 0

      target_positions = {}
      
      target_weights.each do |instrument, weight|
        target_value = total_capital * weight
        price = current_prices[instrument]
        
        next unless price && price > 0
        
        target_qty = (target_value / price).floor # Integer quantities for equities
        target_positions[instrument] = target_qty if target_qty > 0
      end
      
      target_positions
    end
  end
end
