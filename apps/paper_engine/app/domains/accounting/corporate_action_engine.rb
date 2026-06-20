module Accounting
  class CorporateActionEngine
    def self.apply(corporate_action)
      return if corporate_action.status == 'APPLIED'

      case corporate_action.action_type
      when 'DIVIDEND'
        apply_dividend(corporate_action)
      when 'SPLIT'
        apply_split(corporate_action)
      when 'BONUS'
        apply_bonus(corporate_action)
      end

      corporate_action.update!(status: 'APPLIED')
    end

    private

    def self.apply_dividend(action)
      amount_per_share = action.details['amount'].to_f
      
      # Find all settled lots for this symbol
      SettlementLot.where(symbol: action.symbol, status: 'SETTLED').each do |lot|
        total_dividend = lot.quantity * amount_per_share
        
        # Add cash to margin account
        ma = Broker::MarginAccount.find_by(runtime_id: lot.runtime_id, account_id: lot.account_id)
        if ma
          ma.update!(cash_balance: ma.cash_balance + total_dividend)
        end

        PortfolioCashflow.create!(
          runtime_id: lot.runtime_id,
          account_id: lot.account_id,
          cashflow_type: 'DIVIDEND',
          amount: total_dividend,
          reference_id: action.id.to_s,
          reference_type: 'CorporateAction'
        )

        Events::DomainEvent.create!(
          runtime_id: lot.runtime_id,
          event_type: 'dividend.credited',
          payload: { symbol: action.symbol, amount: total_dividend },
          occurred_at: Time.current
        )
      end
    end

    def self.apply_split(action)
      ratio = action.details['ratio'] # e.g. "1:5" means 1 old share becomes 5 new shares
      old_qty, new_qty = ratio.split(':').map(&:to_i)
      multiplier = new_qty.to_f / old_qty

      SettlementLot.where(symbol: action.symbol, status: 'SETTLED').each do |lot|
        new_quantity = (lot.quantity * multiplier).to_i
        lot.update!(quantity: new_quantity)
        
        # Need to also update the underlying trade price/quantity to preserve history/cost basis
        # Or we can just handle it on the fly, but for simplicity we'll just emit an event
        Events::DomainEvent.create!(
          runtime_id: lot.runtime_id,
          event_type: 'split.applied',
          payload: { symbol: action.symbol, multiplier: multiplier },
          occurred_at: Time.current
        )
      end
    end

    def self.apply_bonus(action)
      ratio = action.details['ratio'] # e.g. "1:1"
      new_shares, old_shares = ratio.split(':').map(&:to_i)
      multiplier = new_shares.to_f / old_shares

      SettlementLot.where(symbol: action.symbol, status: 'SETTLED').each do |lot|
        bonus_qty = (lot.quantity * multiplier).to_i
        lot.update!(quantity: lot.quantity + bonus_qty)

        Events::DomainEvent.create!(
          runtime_id: lot.runtime_id,
          event_type: 'bonus.issued',
          payload: { symbol: action.symbol, bonus_quantity: bonus_qty },
          occurred_at: Time.current
        )
      end
    end
  end
end
