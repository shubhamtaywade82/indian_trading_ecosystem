module Market
  class SessionEngine
    def self.evaluate(runtime)
      time = MarketClock.current_time(runtime)
      
      # Mocking session timings: 09:15 to 15:30
      hour = time.hour
      minute = time.min

      time_in_minutes = hour * 60 + minute
      market_open = 9 * 60 + 15
      market_close = 15 * 60 + 30

      if time_in_minutes < market_open || time_in_minutes >= market_close
        { success: false, reason: 'MARKET_CLOSED' }
      else
        { success: true }
      end
    end
  end
end
