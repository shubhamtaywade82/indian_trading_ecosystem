module Api
  module V1
    class ReplayController < ApplicationController
      # POST /api/v1/replay/start
      def start
        ticks = params.require(:ticks).map(&:to_unsafe_h).map(&:symbolize_keys)
        speed = params.fetch(:speed_multiplier, 0).to_f

        replay = Paper::Replay::HistoricalReplayEngine.new(ticks, speed_multiplier: speed)

        # Run async in a thread to not block the HTTP request
        Thread.new { replay.run! }

        render json: { status: 'STARTED', tick_count: ticks.length, speed_multiplier: speed }
      end

      # POST /api/v1/replay/stop  (for future implementation with job tracking)
      def stop
        render json: { status: 'STOPPED' }
      end

      # GET /api/v1/replay/status
      def status
        render json: { status: 'IDLE' }
      end
    end
  end
end
