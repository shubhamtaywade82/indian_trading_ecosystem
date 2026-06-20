module Execution
  class SlippageEngine
    def self.apply(runtime_id, price, quantity, side)
      runtime = Runtime.find(runtime_id)
      model = runtime.slippage_model || 'NONE'

      case model
      when 'NONE'
        price
      when 'FIXED_BPS'
        # e.g., 5 bps
        slippage = price * 0.0005
        side == 'BUY' ? price + slippage : price - slippage
      when 'DEPTH_BASED'
        # Simulating impact. For every 1000 shares, slippage increases by 1 bps
        impact_bps = (quantity / 1000.0) * 0.0001
        slippage = price * impact_bps
        side == 'BUY' ? price + slippage : price - slippage
      when 'VOLATILITY_BASED'
        # Random variance
        price # Simplified
      else
        price
      end
    end
  end
end
