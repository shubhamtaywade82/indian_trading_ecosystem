module Api
  module V1
    class MarginController < ApplicationController
      # GET /api/v1/margin
      def index
        ma = MarginAccount.find_by(account_id: current_account.id)
        render json: {
          cash_balance:      ma&.cash_balance || 0,
          blocked_margin:    ma&.blocked_margin || 0,
          available_margin:  ma&.available_margin || 0,
          mtm_pnl:           ma&.mtm_pnl || 0,
          realized_pnl:      ma&.realized_pnl || 0
        }
      end

      # POST /api/v1/margin/calculate
      def calculate
        result = Paper::Broker::RmsEngine.evaluate(
          account: current_account,
          instrument_id: params[:instrument_id],
          product_type: params[:product_type] || 'CNC',
          side: params[:side] || 'buy',
          qty: params[:qty].to_i,
          price: params[:price].to_f
        )
        render json: { required_margin: result[:required_margin], calculation: result }
      end
    end
  end
end
