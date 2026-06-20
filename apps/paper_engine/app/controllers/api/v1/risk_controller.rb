module Api
  module V1
    class RiskController < ApplicationController
      # GET /api/v1/risk/portfolio
      def portfolio
        profile = PaperRiskProfile.find_by(account: current_account, strategy_id: nil)
        render json: profile || {}
      end

      # GET /api/v1/risk/snapshot
      def snapshot
        profiles = PaperRiskProfile.where(account: current_account)
        render json: profiles
      end

      # POST /api/v1/risk/kill_switch
      def kill_switch
        result = Paper::Risk::KillSwitch.halt!(
          account_id: current_account.id,
          strategy_id: params[:strategy_id],
          reason: params[:reason] || 'MANUAL'
        )
        render json: { status: 'HALTED', details: result }
      end
    end
  end
end
