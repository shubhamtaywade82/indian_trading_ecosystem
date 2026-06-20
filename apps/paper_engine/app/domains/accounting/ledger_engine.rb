module Accounting
  class LedgerEngine
    def self.process(trade)
      account = trade.order.account
      runtime = trade.runtime

      LedgerEntry.transaction do
        # Debit Inventory
        LedgerEntry.create!(
          runtime: runtime,
          account: account,
          entry_type: "debit",
          account_code: "Inventory:#{trade.symbol}",
          debit: trade.trade_value,
          credit: 0,
          reference_type: "Trade",
          reference_id: trade.id
        )

        # Credit Cash
        LedgerEntry.create!(
          runtime: runtime,
          account: account,
          entry_type: "credit",
          account_code: "Cash",
          debit: 0,
          credit: trade.trade_value,
          reference_type: "Trade",
          reference_id: trade.id
        )

        # Verify balance
        debits = LedgerEntry.where(reference_type: "Trade", reference_id: trade.id).sum(:debit)
        credits = LedgerEntry.where(reference_type: "Trade", reference_id: trade.id).sum(:credit)
        
        raise "Imbalance" if debits != credits
      end
    end
  end
end
