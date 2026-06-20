module Paper
  module Risk
    class PortfolioRiskEngine
      def self.evaluate(account:, payload:)
        strategy_id = payload[:strategy_id]
        instrument_id = payload[:instrument_id]
        side = payload[:side]
        qty = payload[:qty]
        price = payload[:price] || 0

        # 1. Kill Switch Check
        ks_result = KillSwitch.evaluate(account_id: account.id, strategy_id: strategy_id)
        return ks_result unless ks_result[:success]

        # Fetch active profile
        profile = PaperRiskProfile.find_by(account_id: account.id, strategy_id: strategy_id) || 
                  PaperRiskProfile.find_by(account_id: account.id, strategy_id: nil)

        return { success: true } unless profile

        margin_acc = MarginAccount.find_by(account_id: account.id)
        if margin_acc
          total_loss = (margin_acc.mtm_pnl || 0) + (margin_acc.realized_pnl || 0)
          
          if profile.max_daily_loss && total_loss < 0 && total_loss.abs > profile.max_daily_loss
            KillSwitch.halt!(account_id: account.id, strategy_id: strategy_id, reason: "Daily loss breached")
            return { success: false, reason: "RISK_BREACH: Max daily loss exceeded." }
          end
        end

        # 3. Position Size Check
        if profile.max_position_size
          trade_value = qty * price
          if trade_value > profile.max_position_size
            return { success: false, reason: "RISK_BREACH: Max position size exceeded (" + trade_value.to_s + " > " + profile.max_position_size.to_s + ")" }
          end
        end

        # 4. Symbol Exposure Check
        if profile.max_symbol_exposure_pct && margin_acc
          total_portfolio_value = (margin_acc.cash_balance || 0) + (margin_acc.utilized_margin || 0)
          if total_portfolio_value > 0
            inv_debit = LedgerEntry.where(account: account, ledger_account: "inventory:" + instrument_id).sum(:debit)
            inv_credit = LedgerEntry.where(account: account, ledger_account: "inventory:" + instrument_id).sum(:credit)
            current_exposure = (inv_debit - inv_credit).abs
            
            new_exposure = current_exposure + (qty * price)
            exposure_pct = new_exposure / total_portfolio_value

            if exposure_pct > profile.max_symbol_exposure_pct
              return { success: false, reason: "RISK_BREACH: Symbol exposure limit exceeded." }
            end
          end
        end

        { success: true }
      end
    end
  end
end
