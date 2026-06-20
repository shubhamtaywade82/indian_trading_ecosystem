module Api
  class HealthController < ApplicationController
    def show
      render json: {
        status: "ok",
        timestamp: Time.now.utc.iso8601,
        environment: Rails.env,
        version: "0.1.0"
      }
    end
  end
end