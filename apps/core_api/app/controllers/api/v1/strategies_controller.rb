# frozen_string_literal: true

module Api
  module V1
    class StrategiesController < ApplicationController
      # GET /api/v1/strategies
      def index
        strategies = [
          { id: "ema_xover", name: "EmaXoverMomentum", description: "Exponential Moving Average Crossover Momentum Strategy", parameters: { short_period: 9, long_period: 21 } },
          { id: "options_buying_naked", name: "OptionsBuyingNaked", description: "Naked Options Buying Strategy (ATM/ITM/OTM option contract buying triggered by underlying EMA crossover)", parameters: { short_period: 9, long_period: 21, strike_style: "ATM", strike_offset: 0, expiry_offset: 0 } }
        ]
        render json: strategies
      end

      # GET /api/v1/strategies/:id
      def show
        case params[:id]
        when "ema_xover"
          render json: { id: "ema_xover", name: "EmaXoverMomentum", description: "Exponential Moving Average Crossover Momentum Strategy", parameters: { short_period: 9, long_period: 21 } }
        when "options_buying_naked"
          render json: { id: "options_buying_naked", name: "OptionsBuyingNaked", description: "Naked Options Buying Strategy (ATM/ITM/OTM option contract buying triggered by underlying EMA crossover)", parameters: { short_period: 9, long_period: 21, strike_style: "ATM", strike_offset: 0, expiry_offset: 0 } }
        else
          render json: { error: "Strategy not found" }, status: :not_found
        end
      end
    end
  end
end
