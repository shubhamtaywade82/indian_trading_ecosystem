module Idempotent
  extend ActiveSupport::Concern

  def with_idempotency
    idempotency_key = request.headers['Idempotency-Key']
    
    if idempotency_key.present?
      key_record = IdempotencyKey.find_by(runtime: current_runtime, key: idempotency_key)
      if key_record
        order = current_runtime.orders.find_by(id: key_record.resource_id)
        if order
          render json: { order_id: order.external_order_id, status: order.status.upcase }, status: :ok
          return
        end
      end
    end

    yield

    if response.successful? && idempotency_key.present? && @order_id_for_idempotency
      IdempotencyKey.create!(
        runtime: current_runtime,
        key: idempotency_key,
        resource_type: 'Orders::Order',
        resource_id: @order_id_for_idempotency
      )
    end
  end
end
