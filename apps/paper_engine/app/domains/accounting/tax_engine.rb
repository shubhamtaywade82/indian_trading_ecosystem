module Accounting
  class TaxEngine
    def self.calculate_tax(buy_trade, sell_trade)
      return { type: nil, amount: 0 } unless buy_trade && sell_trade
      
      holding_period = (sell_trade.created_at.to_date - buy_trade.created_at.to_date).to_i
      pnl = (sell_trade.price - buy_trade.price) * [buy_trade.quantity, sell_trade.quantity].min

      if holding_period < 365
        { type: 'STCG', pnl: pnl, estimated_tax: pnl > 0 ? pnl * 0.15 : 0 }
      else
        { type: 'LTCG', pnl: pnl, estimated_tax: pnl > 0 ? pnl * 0.10 : 0 }
      end
    end
  end
end
