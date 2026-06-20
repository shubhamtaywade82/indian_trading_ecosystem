module Paper
  module Accounting
    class CorporateActionEngine
      def self.process_all!(current_date = Date.today)
        actions = CorporateActionEvent.where(ex_date: current_date)
        actions.each do |action|
          apply_action(action)
        end
      end

      def self.apply_action(action)
        case action.action_type
        when 'DIVIDEND'
          apply_dividend(action)
        when 'SPLIT'
          apply_split(action)
        when 'BONUS'
          apply_bonus(action)
        end
      end

      def self.apply_dividend(action)
        # Find all open lots on the instrument
        lots = TradeLot.where(instrument_id: action.instrument_id, status: 'OPEN')
        
        lots.each do |lot|
          dividend_amount = lot.remaining_qty * action.ratio_or_amount
          next if dividend_amount <= 0
          
          ActiveRecord::Base.transaction do
            # Credit Cash, Credit Dividend Income
            JournalEntry.transaction do
              j = JournalEntry.create!(
                account_id: lot.account_id,
                reference_type: 'corporate_action',
                reference_id: action.id,
                description: "Dividend for \#{action.instrument_id}"
              )
              
              j.ledger_entries.create!(
                account_id: lot.account_id,
                ledger_account: 'cash',
                debit: dividend_amount
              )
              j.ledger_entries.create!(
                account_id: lot.account_id,
                ledger_account: 'income:dividend',
                credit: dividend_amount
              )
            end

            ma = MarginAccount.find_by(account_id: lot.account_id)
            ma.update!(cash_balance: ma.cash_balance + dividend_amount) if ma

            PortfolioCashflow.create!(
              account_id: lot.account_id,
              flow_type: 'dividend',
              amount: dividend_amount,
              reference_type: 'corporate_action',
              reference_id: action.id.to_s
            )
          end
        end
      end

      def self.apply_split(action)
        # Ratio e.g. 5 means 1:5 split (1 old share becomes 5 new shares)
        # Price becomes 1/5th
        lots = TradeLot.where(instrument_id: action.instrument_id, status: 'OPEN')
        
        lots.each do |lot|
          ActiveRecord::Base.transaction do
            lot.update!(
              remaining_qty: lot.remaining_qty * action.ratio_or_amount,
              original_qty: lot.original_qty * action.ratio_or_amount,
              entry_price: lot.entry_price / action.ratio_or_amount
            )
            # No ledger change, as total cost basis remains identical!
          end
        end
      end

      def self.apply_bonus(action)
        # Ratio e.g. 1 means 1:1 bonus (get 1 free for every 1 held)
        # Price cost basis becomes: old_qty * old_price / (old_qty + bonus_qty)
        lots = TradeLot.where(instrument_id: action.instrument_id, status: 'OPEN')
        
        lots.each do |lot|
          ActiveRecord::Base.transaction do
            new_qty = lot.remaining_qty + (lot.remaining_qty * action.ratio_or_amount)
            new_price = (lot.remaining_qty * lot.entry_price) / new_qty
            
            lot.update!(
              remaining_qty: new_qty,
              original_qty: new_qty,
              entry_price: new_price
            )
          end
        end
      end
    end
  end
end
