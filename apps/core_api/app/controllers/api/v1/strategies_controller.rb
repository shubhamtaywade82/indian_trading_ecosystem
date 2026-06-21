# frozen_string_literal: true

module Api
  module V1
    class StrategiesController < ApplicationController
      # GET /api/v1/strategies
      def index
        strategies = [
          { id: "ema_xover", name: "EmaXoverMomentum", description: "Exponential Moving Average Crossover Momentum Strategy", parameters: { short_period: 9, long_period: 21 } }
        ]
        render json: strategies
      end

      # GET /api/v1/strategies/:id
      def show
        if params[:id] == "ema_xover"
          render json: { id: "ema_xover", name: "EmaXoverMomentum", description: "Exponential Moving Average Crossover Momentum Strategy", parameters: { short_period: 9, long_period: 21 } }
        else
          render json: { error: "Strategy not found" }, status: :not_found
        end
      end
    end
  end
end
