module Risk
  class DrawdownEngine
    def self.evaluate(runtime_id, strategy_id)
      snapshot = RiskSnapshot.find_or_initialize_by(runtime_id: runtime_id, strategy_id: strategy_id, snapshot_date: Date.today)
      profile = RiskProfile.find_by(runtime_id: runtime_id, strategy_id: strategy_id)
      
      return { success: true } unless profile && profile.max_drawdown_pct

      # In a real system, equity is computed dynamically
      if snapshot.equity > snapshot.peak_equity
        snapshot.peak_equity = snapshot.equity
        snapshot.save!
      end

      return { success: true } if snapshot.peak_equity == 0

      drawdown = (snapshot.equity - snapshot.peak_equity) / snapshot.peak_equity
      snapshot.drawdown_pct = drawdown
      snapshot.save!

      if drawdown.abs > profile.max_drawdown_pct
        { success: false, reason: 'DRAWDOWN_BREACH' }
      else
        { success: true }
      end
    end
  end
end
