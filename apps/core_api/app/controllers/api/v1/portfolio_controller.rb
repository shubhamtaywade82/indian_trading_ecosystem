module Api
  module V1
    # GET /api/v1/portfolio/summary
    # POST /api/v1/portfolio/rebalance
    class PortfolioController < ApplicationController
      def summary
        funds     = execution_gateway.funds
        positions = execution_gateway.positions

        render json: {
          available_cash:   funds&.dig(:available) || 0,
          total_value:      funds&.dig(:available).to_f + position_value(positions),
          position_count:   positions.is_a?(Hash) ? positions.keys.length : positions&.length || 0,
          positions:        positions
        }
      end

      def positions
        render json: execution_gateway.positions
      end

      def weights
        funds     = execution_gateway.funds
        positions = execution_gateway.positions
        total     = funds&.dig(:available).to_f + position_value(positions)
        return render(json: {}) if total == 0

        weights = {}
        if positions.is_a?(Hash)
          positions.each { |sym, data| weights[sym] = (data.is_a?(Hash) ? data[:value].to_f : 0) / total }
        end

        render json: weights
      end

      def cashflows
        # Proxy to paper_engine for full cashflow detail
        render json: execution_gateway.try(:cashflows) || []
      end

      # POST /api/v1/portfolio/rebalance
      # Triggers a full Strategy → Portfolio → Risk → Execution cycle
      def rebalance
        market_data = params.require(:market_data).to_unsafe_h.transform_keys(&:to_s)
                            .transform_values { |candles| candles.map(&:symbolize_keys) }

        strategies = [Strategy::EmaXoverMomentum.new(short_period: 9, long_period: 21)]
        loop_runner = Core::TradingLoop.new(current_runtime_config, mandate, strategies)
        loop_runner.run!(market_data)

        render json: { status: 'REBALANCE_SUBMITTED' }
      end

      private

      def position_value(positions)
        return 0 unless positions.is_a?(Hash)
        positions.values.sum { |v| v.is_a?(Hash) ? v[:value].to_f : 0 }
      end
    end
  end
end
