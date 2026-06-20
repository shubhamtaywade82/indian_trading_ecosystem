module Paper
  class MarketClock
    # Modes: LIVE, REPLAY, BACKTEST
    # By default, use LIVE.
    def self.current_time(mode: 'LIVE', replay_time: nil)
      if mode == 'LIVE'
        Time.current
      elsif mode == 'REPLAY' || mode == 'BACKTEST'
        replay_time || Time.current
      end
    end
  end
end
