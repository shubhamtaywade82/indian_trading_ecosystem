module OMS
  class CancelOrder
    def self.call(order)
      unless %w[open partially_filled].include?(order.status)
        return { success: false, errors: { status: ["Cannot cancel order in status #{order.status}"] } }
      end

      order.cancel!

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
