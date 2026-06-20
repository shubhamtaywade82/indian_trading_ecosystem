module OMS
  class CancelOrder
    def self.call(order)
      unless %w[open partially_filled].include?(order.status)
        return { success: false, errors: { status: ["Cannot cancel order in status #{order.status}"] } }
      end

      order.cancel!

      # Release margin for remaining quantity
      req_margin = Broker::MarginCalculator.calculate(
        segment: order.segment, product_type: order.product_type, symbol: order.symbol,
        price: order.price, quantity: order.quantity - order.filled_quantity
      )
      Broker::RMSEngine.release_margin(order.runtime, order.account, req_margin) if req_margin > 0

      Events::DomainEvent.create!(
        runtime: order.runtime,
        event_type: 'order.cancelled',
        payload: { order_id: order.id },
        occurred_at: Time.current
      )

      { success: true, order: order }
    end
  end
end
