module Api
  module V1
    class OrdersController < ApplicationController
      include Idempotent

      def create
        with_idempotency do
          result = OMS::CreateOrder.call(
            runtime: current_runtime,
            account: current_account,
            params: order_params
          )

          if result[:success]
            @order_id_for_idempotency = result[:order].id
            render json: { order_id: result[:order].external_order_id, status: result[:order].status.upcase }, status: :created
          else
            render json: { errors: result[:errors] }, status: :unprocessable_entity
          end
        end
      end

      def update
        order = current_runtime.orders.find_by!(external_order_id: params[:id])
        result = OMS::ModifyOrder.call(order, params: update_params)

        if result[:success]
          render json: { order_id: result[:order].external_order_id, status: result[:order].status.upcase }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def destroy
        order = current_runtime.orders.find_by!(external_order_id: params[:id])
        result = OMS::CancelOrder.call(order)

        if result[:success]
          render json: { order_id: result[:order].external_order_id, status: result[:order].status.upcase }, status: :ok
        else
          # Return 409 Conflict if cancelling twice or not allowed
          render json: { errors: result[:errors] }, status: :conflict
        end
      end

      def show
        order = current_runtime.orders.find_by!(external_order_id: params[:id])
        render json: { order_id: order.external_order_id, status: order.status.upcase, quantity: order.quantity, price: order.price }
      end

      def index
        orders = current_runtime.orders
        render json: orders.map { |o| { order_id: o.external_order_id, status: o.status.upcase } }
      end

      private

      def order_params
        params.require(:order).permit(:symbol, :side, :quantity, :order_type, :price, :trigger_price, :product_type)
      end

      def update_params
        params.require(:order).permit(:quantity, :price)
      end

      # Mocking current_runtime and current_account for now
      def current_runtime
        Runtime.first || Runtime.create!(name: "Test", mode: "paper", active: true)
      end

      def current_account
        Accounts::Account.first || Accounts::Account.create!(runtime: current_runtime, name: "Test Account", currency: "INR")
      end
    end
  end
end
