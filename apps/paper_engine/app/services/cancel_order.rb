class CancelOrder
  def self.call(order:)
    ActiveRecord::Base.transaction do
      unless order.PENDING? || order.OPEN? || order.PARTIALLY_FILLED?
        raise "Cannot cancel order in terminal state: " + order.status
      end

      from_status = order.status
      
      # RMS Margin Release
      # Only release for OPEN or PARTIALLY_FILLED. If PENDING, it was never blocked (or blocked right before).
      # Actually in our flow, it gets blocked when moving to OPEN.
      if ['OPEN', 'PARTIALLY_FILLED'].include?(order.status)
        req_margin = Paper::Broker::MarginCalculator.calculate(
          instrument_id: order.instrument_id,
          product_type: order.product_type,
          side: order.side,
          qty: order.remaining_qty, # only release remaining!
          price: order.price
        )
        
        margin_acc = MarginAccount.find_by(account_id: order.account.id)
        if margin_acc
          margin_acc.update!(
            blocked_margin: margin_acc.blocked_margin - req_margin,
            available_margin: margin_acc.available_margin + req_margin
          )
        end
      end

      order.cancel!
      order.log_transition(from_status, 'CANCELLED', 'User requested cancellation')
      order
    end
  end
end
