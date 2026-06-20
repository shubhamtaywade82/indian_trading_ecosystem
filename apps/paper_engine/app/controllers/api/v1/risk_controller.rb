module Api
  module V1
    class RiskController < ApplicationController
      def portfolio
        snapshot = Risk::RiskSnapshot.find_by(runtime: current_runtime, strategy_id: nil)
        render json: snapshot || {}
      end

      def strategies
        snapshots = Risk::RiskSnapshot.where(runtime: current_runtime).where.not(strategy_id: nil)
        render json: snapshots
      end

      def snapshot
        render json: Risk::RiskSnapshot.where(runtime: current_runtime)
      end

      def kill_switch
        Risk::KillSwitch.activate!(current_runtime.id, params[:strategy_id], 'MANUAL_INTERVENTION')
        render json: { status: 'STOPPED' }
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end
    end
  end
end
