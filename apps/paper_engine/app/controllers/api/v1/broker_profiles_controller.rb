module Api
  module V1
    class BrokerProfilesController < ApplicationController
      def index
        render json: BrokerProfiles::BrokerProfile.all
      end

      def activate
        profile = BrokerProfiles::BrokerProfile.find(params[:id])
        current_runtime.update!(broker_profile: profile)
        render json: { success: true, active_profile: profile }
      end

      def capabilities
        profile = BrokerProfiles::BrokerProfile.find(params[:id])
        render json: profile.rules
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end
    end
  end
end
