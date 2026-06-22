module Api
  module V1
    # GET  /api/v1/signals
    # POST /api/v1/signals/run
    class SignalsController < ApplicationController
      def index
        # Returns the last generated signal set (stub for now — could be persisted in Redis/DB)
        render json: { message: 'Use POST /api/v1/signals/run with market_data to generate signals' }
      end

      # POST /api/v1/signals/run
      # Body: { market_data: { 'RELIANCE' => [{close: 100}, ...], ... } }
      def run
        market_data = params.require(:market_data).to_unsafe_h.transform_keys(&:to_s)
                            .transform_values { |candles| candles.map(&:symbolize_keys) }

        strategies = registered_strategies
        generator  = Strategy::SignalGenerator.new(strategies)
        signals    = generator.run!(market_data, {})

        render json: signals.map { |s|
          {
            instrument_id: s.instrument_id,
            direction:     s.direction,
            direction_text: s.buy? ? 'BUY' : 'SELL',
            confidence:    s.confidence,
            strategy_name: s.strategy_name,
            metadata:      s.metadata,
            generated_at:  s.generated_at
          }
        }
      end

      private

      def registered_strategies
        [
          Strategy::EmaXoverMomentum.new(short_period: 9,  long_period: 21),
          Strategy::EmaXoverMomentum.new(short_period: 5,  long_period: 13),
          Strategy::OptionsBuyingNaked.new(short_period: 9, long_period: 21, strike_style: "ATM")
        ]
      end
    end
  end
end
