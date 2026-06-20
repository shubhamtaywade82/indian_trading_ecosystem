module Paper
  module Broker
    class RmsEngine
      # Returns { success: true/false, reason: string, required_margin: numeric }
      def self.evaluate(account:, instrument_id:, product_type:, side:, qty:, price:)
        # 1. Product Rules Check
        rule_check = ProductRules.validate(
          instrument_id: instrument_id,
          product_type: product_type,
          side: side,
          account: account
        )
        return rule_check unless rule_check[:success]
        
        # 2. Margin Check
        eval_price = price || 0 
        
        required_margin = MarginCalculator.calculate(
          instrument_id: instrument_id,
          product_type: product_type,
          side: side,
          qty: qty,
          price: eval_price
        )
        
        margin_account = MarginAccount.find_or_create_by!(account_id: account.id) do |ma|
          ma.cash_balance = 0
          ma.blocked_margin = 0
          ma.available_margin = 0
          ma.utilized_margin = 0
          ma.mtm_pnl = 0
          ma.realized_pnl = 0
        end
        
        actual_cash = LedgerEntry.where(account: account, ledger_account: 'cash').sum(:debit) - 
                      LedgerEntry.where(account: account, ledger_account: 'cash').sum(:credit)
        
        margin_account.update!(
          cash_balance: actual_cash,
          available_margin: actual_cash - margin_account.blocked_margin
        )
        
        if margin_account.available_margin < required_margin
          return { success: false, reason: "INSUFFICIENT_FUNDS: required " + required_margin.to_s + ", available " + margin_account.available_margin.to_s }
        end
        
        { success: true, required_margin: required_margin }
      end
    end
  end
end
