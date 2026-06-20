module Risk
  class DailyLossEngine
    def self.evaluate(runtime_id, strategy_id)
      snapshot = RiskSnapshot.find_by(runtime_id: runtime_id, strategy_id: strategy_id, snapshot_date: Date.today)
      profile = RiskProfile.find_by(runtime_id: runtime_id, strategy_id: strategy_id)

      return { success: true } unless snapshot && profile && profile.max_daily_loss

      if snapshot.daily_pnl < 0 && snapshot.daily_pnl.abs > profile.max_daily_loss
        { success: false, reason: 'DAILY_LOSS_BREACH' }
      else
        { success: true }
      end
    end
  end
end
