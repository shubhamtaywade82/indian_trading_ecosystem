module Api
  module V1
    # POST /api/v1/orders
    # DELETE /api/v1/orders/:id
    # Core API never touches the matching engine directly.
    # All orders flow through ExecutionGateway → appropriate adapter.
    class OrdersController < ApplicationController
      def create
        payload = order_params.to_h.symbolize_keys
        result = execution_gateway.place_order(payload)
        render json: result, status: :created
      end

      def index
        render json: execution_gateway.orders
      end

      def show
        orders = execution_gateway.orders
        order  = orders.find { |o| o[:id].to_s == params[:id] }
        order ? render(json: order) : render(json: { error: 'Not found' }, status: :not_found)
      end

      def destroy
        result = execution_gateway.cancel_order(params[:id])
        render json: result
      end

      private

      def order_params
        params.require(:order).permit(
          :instrument_id, :side, :order_type, :product_type,
          :qty, :price, :trigger_price, :strategy_id
        )
      end
    end
  end
end
