module Paper
  module Execution
    class SlippageEngine
      # Slippage models: NONE, FIXED_BPS, PERCENTAGE, DEPTH_BASED
      def self.calculate(side:, price:, qty:, model: 'FIXED_BPS', value: 5.0)
        return price if model == 'NONE'

        if model == 'FIXED_BPS'
          # e.g., 5 bps = 0.0005
          slippage_pct = value / 10000.0
          if side == 'buy'
            price * (1 + slippage_pct)
          else
            price * (1 - slippage_pct)
          end
        elsif model == 'PERCENTAGE'
          slippage_pct = value / 100.0
          if side == 'buy'
            price * (1 + slippage_pct)
          else
            price * (1 - slippage_pct)
          end
        elsif model == 'DEPTH_BASED'
          # Stub for depth-based. A large order impacts price more.
          # We'd look at OrderBook depth. For now, simulate with a formula:
          impact = (qty / 1000.0) * 0.001 # 0.1% for every 1000 shares
          if side == 'buy'
            price * (1 + impact)
          else
            price * (1 - impact)
          end
        else
          price
        end
      end
    end
  end
end
