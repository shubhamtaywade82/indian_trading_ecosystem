# frozen_string_literal: true

module Api
  module V1
    class StrategiesController < ApplicationController
      # GET /api/v1/strategies
      def index
        strategies = [
          { id: "ema_xover", name: "EmaXoverMomentum", description: "Exponential Moving Average Crossover Momentum Strategy", parameters: { short_period: 9, long_period: 21 } },
          { id: "options_buying_naked", name: "OptionsBuyingNaked", description: "Naked Options Buying Strategy (ATM/ITM/OTM option contract buying triggered by underlying EMA crossover)", parameters: { short_period: 9, long_period: 21, strike_style: "ATM", strike_offset: 0, expiry_offset: 0 } },
          { id: "opening_range_breakout", name: "OpeningRangeBreakout", description: "Opening Range Breakout Strategy (buying options triggered by spot high/low breakout during market open)", parameters: { orb_minutes: 15, strike_style: "ATM", strike_offset: 0, expiry_offset: 0 } },
          { id: "triple_timeframe_alignment", name: "TripleTimeframeAlignment", description: "Triple Timeframe Alignment Pullback Strategy (buying options when daily, hourly, and 15m trends pull back and reverse)", parameters: { short_ema_period: 20, long_ema_period: 50, strike_style: "ATM", strike_offset: 0 } },
          { id: "vix_mean_reversion", name: "VixMeanReversion", description: "VIX Mean Reversion Expansion Strategy (buying options when VIX breaks out of a compressed historical percentile)", parameters: { vix_percentile_threshold: 20, vix_compression_bars: 3, vix_rise_pct: 0.05, strike_style: "ATM", strike_offset: 0 } }
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
        when "opening_range_breakout"
          render json: { id: "opening_range_breakout", name: "OpeningRangeBreakout", description: "Opening Range Breakout Strategy (buying options triggered by spot high/low breakout during market open)", parameters: { orb_minutes: 15, strike_style: "ATM", strike_offset: 0, expiry_offset: 0 } }
        when "triple_timeframe_alignment"
          render json: { id: "triple_timeframe_alignment", name: "TripleTimeframeAlignment", description: "Triple Timeframe Alignment Pullback Strategy (buying options when daily, hourly, and 15m trends pull back and reverse)", parameters: { short_ema_period: 20, long_ema_period: 50, strike_style: "ATM", strike_offset: 0 } }
        when "vix_mean_reversion"
          render json: { id: "vix_mean_reversion", name: "VixMeanReversion", description: "VIX Mean Reversion Expansion Strategy (buying options when VIX breaks out of a compressed historical percentile)", parameters: { vix_percentile_threshold: 20, vix_compression_bars: 3, vix_rise_pct: 0.05, strike_style: "ATM", strike_offset: 0 } }
        else
          render json: { error: "Strategy not found" }, status: :not_found
        end
      end
    end
  end
end
