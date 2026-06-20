module Paper
  module Accounting
    class TaxEngine
      def self.handle_consumption(consumption)
        trade_lot = consumption.trade_lot
        closing_trade = consumption.closing_trade
        
        # Determine holding period
        holding_period_days = (closing_trade.exchange_ts.to_date - trade_lot.opening_trade.exchange_ts.to_date).to_i
        
        is_ltcg = holding_period_days >= 365
        tax_type = is_ltcg ? 'LTCG' : 'STCG'
        
        # Realized PnL is already on consumption
        pnl = consumption.realized_pnl
        
        # Log to ledger or a dedicated TaxReport model. For paper engine, just standard ledger entry for tracking
        # For simulation grade, we just emit an event or create a journal entry. Let's create a journal entry for tax tracking.
        # We don't deduct cash for taxes, we just accrue tax liability!
        
        # Tax rates (approximate for India equity)
        # STCG: 20% (new budget), LTCG: 12.5% (new budget) - let's use 15% / 10% for simplicity if older.
        # Just use simple modern ones: STCG: 20%, LTCG: 12.5%
        rate = is_ltcg ? 0.125 : 0.20
        tax_liability = [pnl * rate, 0].max
        
        return if tax_liability == 0
        
        JournalEntry.transaction do
          j = JournalEntry.create!(
            account_id: trade_lot.account_id,
            reference_type: 'tax_liability',
            reference_id: consumption.id,
            description: "\#{tax_type} Liability for consumption \#{consumption.id}"
          )
          
          # Debit PnL (expense), Credit Tax Payable (liability)
          j.ledger_entries.create!(
            account_id: trade_lot.account_id,
            ledger_account: "expense:tax:\#{tax_type.downcase}",
            debit: tax_liability
          )
          j.ledger_entries.create!(
            account_id: trade_lot.account_id,
            ledger_account: "liability:tax_payable",
            credit: tax_liability
          )
        end
      end
    end
  end
end
