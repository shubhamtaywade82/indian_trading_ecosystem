module Paper
  module Accounting
    class ChargesEngine
      def self.calculate(trade)
        # Default fallback values for testing if no profile
        # Use simple profile lookup by broker string or default to 'paper-generic'
        # A real system would resolve broker from runtime or account
        profile = ChargeProfile.find_by(broker: 'paper-generic', product_type: trade.paper_order.product_type)
        
        value = trade.fill_value
        
        if profile
          brokerage = profile.brokerage_flat || (value * (profile.brokerage_pct || 0))
          stt = value * (profile.stt_pct || 0)
          exchange = value * (profile.exchange_pct || 0)
          sebi = value * (profile.sebi_pct || 0)
          stamp = value * (profile.stamp_pct || 0)
          gst = (brokerage + exchange + sebi) * (profile.gst_pct || 0.18)
        else
          brokerage = 0
          stt = 0
          exchange = 0
          sebi = 0
          stamp = 0
          gst = 0
        end
        
        {
          brokerage: brokerage.round(4),
          stt: stt.round(4),
          exchange: exchange.round(4),
          sebi: sebi.round(4),
          stamp: stamp.round(4),
          gst: gst.round(4),
          total: (brokerage + stt + exchange + sebi + stamp + gst).round(4)
        }
      end

      def self.post_to_ledger!(trade)
        charges = calculate(trade)
        return if charges[:total] == 0

        # Create one journal entry for all charges of this trade
        journal = JournalEntry.create!(
          account_id: trade.account_id,
          reference_type: 'trade_charges',
          reference_id: trade.id,
          description: "Charges for trade #{trade.id}"
        )

        charges.each do |charge_type, amount|
          next if charge_type == :total || amount == 0
          
          # Debit the specific expense account
          journal.ledger_entries.create!(
            account_id: trade.account_id,
            ledger_account: "expense:#{charge_type}",
            debit: amount
          )
        end
        
        # Credit cash for the total
        journal.ledger_entries.create!(
          account_id: trade.account_id,
          ledger_account: 'cash',
          credit: charges[:total]
        )

        # Update MarginAccount cash balance
        ma = MarginAccount.find_by(account_id: trade.account_id)
        if ma
          ma.update!(cash_balance: ma.cash_balance - charges[:total])
        end

        # Create PortfolioCashflow record
        PortfolioCashflow.create!(
          account_id: trade.account_id,
          flow_type: 'charges',
          amount: -charges[:total],
          reference_type: 'trade',
          reference_id: trade.id.to_s
        )

        charges
      end
    end
  end
end
