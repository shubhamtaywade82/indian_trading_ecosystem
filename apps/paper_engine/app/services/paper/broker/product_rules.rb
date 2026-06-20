module Paper
  module Broker
    class ProductRules
      def self.validate(instrument_id:, product_type:, side:, account:)
        case product_type
        when 'CNC'
          if side == 'sell'
            # Short selling is not allowed in CNC unless holding exists.
            # Look up inventory from ledger.
            inventory_balance = LedgerEntry.where(account: account, ledger_account: "inventory:#{instrument_id}").sum(:credit) - 
                                LedgerEntry.where(account: account, ledger_account: "inventory:#{instrument_id}").sum(:debit)
            
            # Since asset inventory is debit normal, credit means sold. Wait.
            # Asset = Debit increases, Credit decreases.
            # So inventory is Debit - Credit
            inventory = LedgerEntry.where(account: account, ledger_account: "inventory:#{instrument_id}").sum(:debit) - 
                        LedgerEntry.where(account: account, ledger_account: "inventory:#{instrument_id}").sum(:credit)
                        
            if inventory <= 0
              return { success: false, reason: 'Short selling not allowed in CNC without holdings' }
            end
          end
        when 'MIS'
          # MIS allows short selling intraday
        when 'NRML'
          # NRML allows futures/options carry forward
        end
        
        { success: true }
      end
    end
  end
end
