module Replay
  class HistoricalReplayEngine
    def self.start(runtime_id, start_time, end_time, mode = 'TICK')
      session = ReplaySession.create!(
        runtime_id: runtime_id,
        status: 'ACTIVE',
        mode: mode,
        start_time: start_time,
        current_time: start_time,
        end_time: end_time
      )

      # In a real system, this would spawn a background worker that fetches ticks from
      # the Core Platform and processes them chronologically via TickProcessor.
      # For simulation purposes, we just return the session.
      session
    end

    def self.advance_tick(session_id, tick_data, timestamp)
      session = ReplaySession.find(session_id)
      return unless session.status == 'ACTIVE'

      session.update!(current_time: timestamp)

      Exchange::TickProcessor.process(
        runtime_id: session.runtime_id,
        symbol: tick_data[:symbol],
        tick: tick_data
      )

      Events::DomainEvent.create!(
        runtime_id: session.runtime_id,
        event_type: 'replay.tick',
        payload: { current_time: timestamp, symbol: tick_data[:symbol] },
        occurred_at: Time.current
      )

      if session.current_time >= session.end_time
        session.update!(status: 'COMPLETED')
      end
    end
  end
end
