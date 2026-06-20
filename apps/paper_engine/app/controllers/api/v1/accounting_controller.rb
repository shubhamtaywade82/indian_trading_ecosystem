module Api
  module V1
    class AccountingController < ApplicationController
      def charges
        # Simplified response
        render json: Accounting::PortfolioCashflow.where(runtime: current_runtime, cashflow_type: 'CHARGES')
      end

      def settlements
        render json: Accounting::SettlementLot.where(runtime: current_runtime)
      end

      def corporate_actions
        render json: Accounting::CorporateAction.where(runtime: current_runtime)
      end

      def dividends
        render json: Accounting::PortfolioCashflow.where(runtime: current_runtime, cashflow_type: 'DIVIDEND')
      end

      def tax_summary
        # Simplified. A real implementation would scan all BUY/SELL pairs and compute TaxEngine per pair.
        render json: { stcg: 0, ltcg: 0 }
      end

      def cashflows
        render json: Accounting::PortfolioCashflow.where(runtime: current_runtime)
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end
    end
  end
end
