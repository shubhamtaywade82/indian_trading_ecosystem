module Projections
  class HoldingProjector
    def self.call(trade)
      holding = Holding.find_or_initialize_by(
        runtime: trade.runtime,
        account: trade.order.account,
        symbol: trade.symbol
      )

      holding.with_lock do
        if trade.side == "BUY"
          new_quantity = holding.quantity + trade.quantity
          total_value = (holding.quantity * holding.average_price) + trade.trade_value
          holding.average_price = new_quantity.zero? ? 0 : (total_value / new_quantity)
          holding.quantity = new_quantity
        elsif trade.side == "SELL"
          raise "Oversell" if holding.quantity < trade.quantity
          holding.quantity -= trade.quantity
        end
        holding.save!
      end
    end
  end
end
