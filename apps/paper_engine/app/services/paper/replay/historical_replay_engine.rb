module Paper
  module Replay
    class HistoricalReplayEngine
      attr_reader :ticks, :speed_multiplier

      # ticks: Array of hashes [{instrument_id: '...', ltp: 100, volume: 500, time: Time}]
      # speed_multiplier: 1.0 is realtime, 10.0 is 10x speed, 0 is max speed (as fast as possible)
      def initialize(ticks, speed_multiplier: 0)
        @ticks = ticks.sort_by { |t| t[:time] }
        @speed_multiplier = speed_multiplier
      end

      def run!
        return if @ticks.empty?

        start_time = Time.current
        first_tick_time = @ticks.first[:time]

        @ticks.each do |tick|
          if @speed_multiplier > 0
            # Calculate how much we should wait
            elapsed_virtual = tick[:time] - first_tick_time
            elapsed_real = Time.current - start_time
            
            target_real_elapsed = elapsed_virtual / @speed_multiplier
            
            sleep_time = target_real_elapsed - elapsed_real
            sleep(sleep_time) if sleep_time > 0
          end
          
          # We need a way to mock Time.current while this runs if the system relies on it
          # In ruby, Timecop.travel or ActiveSupport::Testing::TimeHelpers
          # For paper engine, MarketClock can return this tick's time
          
          MatchingEngine.process_tick(tick)
        end
      end
    end
  end
end
