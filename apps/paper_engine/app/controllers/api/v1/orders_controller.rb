module Api
  module V1
    class OrdersController < ApplicationController
      # POST /api/v1/orders
      def create
        order = PlaceOrder.call(account: current_account, payload: order_params.to_h.symbolize_keys)
        render json: serialize_order(order), status: order.status == 'REJECTED' ? :unprocessable_entity : :created
      end

      # GET /api/v1/orders
      def index
        orders = PaperOrder.where(account: current_account).order(created_at: :desc).limit(100)
        render json: orders.map { |o| serialize_order(o) }
      end

      # GET /api/v1/orders/:id
      def show
        order = PaperOrder.find_by!(id: params[:id], account: current_account)
        render json: serialize_order(order)
      end

      # DELETE /api/v1/orders/:id (cancel)
      def destroy
        order = PaperOrder.find_by!(id: params[:id], account: current_account)

        if order.cancellable?
          order.cancel!
          order.log_transition(order.status, 'CANCELLED', 'Cancelled by user')
          render json: serialize_order(order)
        else
          render json: { error: 'Order cannot be cancelled in its current state' }, status: :conflict
        end
      end

      private

      def order_params
        params.require(:order).permit(
          :instrument_id, :side, :order_type, :product_type, :qty, :price,
          :trigger_price, :tif, :strategy_id, :client_order_id
        )
      end

      def serialize_order(order)
        {
          id: order.id,
          instrument_id: order.instrument_id,
          side: order.side,
          order_type: order.order_type,
          product_type: order.product_type,
          qty: order.qty,
          price: order.price,
          status: order.status,
          strategy_id: order.strategy_id,
          client_order_id: order.client_order_id,
          created_at: order.created_at
        }
      end
    end
  end
end
