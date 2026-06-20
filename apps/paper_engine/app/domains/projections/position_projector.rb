module Projections
  class PositionProjector
    def self.call(trade)
      position = Position.find_or_initialize_by(
        runtime: trade.runtime,
        account: trade.order.account,
        symbol: trade.symbol
      )

      position.with_lock do
        if trade.side == "BUY"
          new_quantity = position.quantity + trade.quantity
          total_value = (position.quantity * position.average_price) + trade.trade_value
          position.average_price = new_quantity.zero? ? 0 : (total_value / new_quantity)
          position.quantity = new_quantity
        elsif trade.side == "SELL"
          raise "Oversell" if position.quantity < trade.quantity
          position.quantity -= trade.quantity
        end

        position.save!
      end
    end
  end
end
