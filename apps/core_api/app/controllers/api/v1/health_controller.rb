module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: {
          status: 'ok',
          service: 'core_api',
          timestamp: Time.current.iso8601,
          version: 'v1'
        }
      end
    end
  end
end
