module Api
  class PositionsController < ApplicationController
    def index
      positions = PositionTracker.all
      render json: { positions: positions.map(&:to_h), count: positions.count }
    end

    def summary
      open_count = PositionTracker.where(status: :active).count
      closed_count = PositionTracker.where(status: :exited).count

      render json: {
        open_count: open_count,
        closed_count: closed_count,
        timestamp: Time.now.utc.iso8601
      }
    end
  end
end