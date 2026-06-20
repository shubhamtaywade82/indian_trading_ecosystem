module Api
  module V1
    class AccountingController < ApplicationController
      # GET /api/v1/accounting/charges
      def charges
        cashflows = PortfolioCashflow.where(account_id: current_account.id, flow_type: 'charges').order(created_at: :desc)
        render json: cashflows.map { |c| { amount: c.amount, reference_id: c.reference_id, created_at: c.created_at } }
      end

      # GET /api/v1/accounting/settlements
      def settlements
        lots = SettlementLot.joins("INNER JOIN paper_trades ON paper_trades.id = settlement_lots.trade_id")
                            .where(paper_trades: { account_id: current_account.id })
        render json: lots.map { |l| { trade_id: l.trade_id, symbol: l.symbol, qty: l.quantity, status: l.status, settlement_date: l.settlement_date } }
      end

      # GET /api/v1/accounting/corporate_actions
      def corporate_actions
        actions = CorporateActionEvent.all.order(ex_date: :desc).limit(100)
        render json: actions
      end

      # GET /api/v1/accounting/dividends
      def dividends
        cashflows = PortfolioCashflow.where(account_id: current_account.id, flow_type: 'dividend').order(created_at: :desc)
        render json: cashflows.map { |c| { amount: c.amount, reference_id: c.reference_id, created_at: c.created_at } }
      end

      # GET /api/v1/accounting/tax_summary
      def tax_summary
        stcg = LedgerEntry.where(account: current_account, ledger_account: 'expense:tax:stcg').sum(:debit)
        ltcg = LedgerEntry.where(account: current_account, ledger_account: 'expense:tax:ltcg').sum(:debit)
        render json: { stcg: stcg, ltcg: ltcg, total: stcg + ltcg }
      end

      # GET /api/v1/accounting/cashflows
      def cashflows
        flows = PortfolioCashflow.where(account_id: current_account.id).order(created_at: :desc).limit(200)
        render json: flows.map { |c| { flow_type: c.flow_type, amount: c.amount, reference_type: c.reference_type, reference_id: c.reference_id, created_at: c.created_at } }
      end
    end
  end
end
