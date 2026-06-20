class ModifyOrder
  def self.call(order:, new_qty: nil, new_price: nil)
    ActiveRecord::Base.transaction do
      unless order.OPEN? || order.PARTIALLY_FILLED?
        raise "Cannot modify order in state: " + order.status
      end

      payload = {
        instrument_id: order.instrument_id,
        side: order.side,
        order_type: order.order_type,
        product_type: order.product_type,
        qty: new_qty || order.qty,
        price: new_price || order.price,
        trigger_price: order.trigger_price
      }

      validator = OrderValidator.new
      result = validator.call(payload)

      if result.success?
        if new_qty && new_qty < order.filled_qty
          raise "Cannot modify qty below filled quantity (" + order.filled_qty.to_s + ")"
        end
        
        order.update!(qty: payload[:qty], price: payload[:price])
        order.log_transition(order.status, order.status, "Order modified: qty=" + payload[:qty].to_s + ", price=" + payload[:price].to_s)
        order
      else
        raise "Modification validation failed: " + result.errors.to_h.inspect
      end
    end
  end
end
