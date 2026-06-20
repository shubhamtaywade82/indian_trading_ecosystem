module Api
  module V1
    class ReplayController < ApplicationController
      def start
        session = Replay::HistoricalReplayEngine.start(
          current_runtime.id,
          params[:start_time] ? Time.parse(params[:start_time]) : 1.day.ago,
          params[:end_time] ? Time.parse(params[:end_time]) : Time.current,
          params[:mode] || 'TICK'
        )
        render json: session
      end

      def pause
        session = Replay::ReplaySession.find_by(runtime_id: current_runtime.id, status: 'ACTIVE')
        session&.update!(status: 'PAUSED')
        render json: { status: 'PAUSED' }
      end

      def resume
        session = Replay::ReplaySession.find_by(runtime_id: current_runtime.id, status: 'PAUSED')
        session&.update!(status: 'ACTIVE')
        render json: { status: 'ACTIVE' }
      end

      def status
        session = Replay::ReplaySession.where(runtime_id: current_runtime.id).last
        render json: session || {}
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end
    end
  end
end
