module Api
  module V1
    class MarginController < ApplicationController
      def index
        margin_account = Broker::MarginAccount.find_by(runtime: current_runtime, account: current_account)
        if margin_account
          render json: {
            cash: margin_account.cash_balance,
            blocked: margin_account.blocked_margin,
            available: margin_account.available_margin
          }
        else
          render json: { cash: 0, blocked: 0, available: 0 }
        end
      end

      def calculate
        req_margin = Broker::MarginCalculator.calculate(
          symbol: params[:symbol],
          quantity: params[:quantity],
          product_type: params[:product_type],
          price: params[:price]
        )
        render json: { required_margin: req_margin }
      end

      private

      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end

      def current_account
        Accounts::Account.first || Accounts::Account.create!(runtime: current_runtime, name: "Test Account", currency: "INR")
      end
    end
  end
end
