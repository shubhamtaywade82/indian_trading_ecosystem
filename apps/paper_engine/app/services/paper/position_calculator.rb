# frozen_string_literal: true

module Paper
  class PositionCalculator
    def self.position_for(account, instrument_id)
      lots = TradeLot.where(account: account, instrument_id: instrument_id)
      buy_lots = lots.where(side: "buy")
      sell_lots = lots.where(side: "sell")

      total_bought = buy_lots.sum(:original_qty)
      total_sold = sell_lots.sum(:original_qty)
      net_qty = total_bought - total_sold

      open_lots = buy_lots.where(status: "open")
      total_remaining = open_lots.sum(:remaining_qty)
      total_cost = open_lots.sum("remaining_qty * entry_price")

      avg_price = if total_remaining > 0
        total_cost.to_f / total_remaining
      else
        0
      end

      realized_pnl = LotConsumption.joins(:trade_lot)
        .where(trade_lots: { account: account, instrument_id: instrument_id })
        .sum(:realized_pnl)

      { net_qty: net_qty, avg_price: avg_price, realized_pnl: realized_pnl }
    end

    def self.all_positions(account)
      instruments = TradeLot.where(account: account)
        .distinct.pluck(:instrument_id)

      instruments.map do |instrument_id|
        pos = position_for(account, instrument_id)
        pos.merge(instrument_id: instrument_id)
      end.reject { |p| p[:net_qty] == 0 }
    end

    def self.cash_balance(account)
      debits = LedgerEntry.where(account: account, ledger_account: "cash").sum(:debit)
      credits = LedgerEntry.where(account: account, ledger_account: "cash").sum(:credit)
      account.starting_balance + debits - credits
    end
  end
end