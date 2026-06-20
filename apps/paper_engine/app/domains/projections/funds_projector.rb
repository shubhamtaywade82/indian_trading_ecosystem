module Projections
  class FundsProjector
    def self.call(trade)
      fund = Fund.find_or_initialize_by(
        runtime: trade.runtime,
        account: trade.order.account
      )

      fund.with_lock do
        if trade.side == "BUY"
          fund.cash_balance -= trade.trade_value
        elsif trade.side == "SELL"
          fund.cash_balance += trade.trade_value
        end
        fund.save!
      end
    end
  end
end
