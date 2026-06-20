module OMS
  class ModifyOrder
    def self.call(order, params:)
      unless %w[open partially_filled].include?(order.status)
        return { success: false, errors: { status: ["Cannot modify order in status #{order.status}"] } }
      end

      # For simplicity, only validate price and quantity
      new_quantity = params[:quantity] || order.quantity
      new_price = params[:price] || order.price

      if new_quantity <= 0
        return { success: false, errors: { quantity: ["must be greater than 0"] } }
      end

      order.update!(quantity: new_quantity, price: new_price)

      Events::DomainEvent.create!(
        runtime: order.runtime,
        event_type: 'order.modified',
        payload: { order_id: order.id },
        occurred_at: Time.current
      )

      { success: true, order: order }
    end
  end
end
