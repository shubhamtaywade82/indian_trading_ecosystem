module Market
  class MarketClock
    def self.current_time(runtime)
      if runtime.mode == 'replay' || runtime.mode == 'backtest'
        session = Replay::ReplaySession.find_by(runtime_id: runtime.id, status: 'ACTIVE')
        session ? session.current_time : Time.current
      else
        Time.current
      end
    end
  end
end
