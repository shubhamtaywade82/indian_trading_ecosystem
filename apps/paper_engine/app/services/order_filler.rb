class OrderFiller
  def self.call(order:, fill_qty:, fill_price:)
    ActiveRecord::Base.transaction do
      unless order.OPEN? || order.PARTIALLY_FILLED?
        raise "Cannot fill order in state " + order.status
      end
      
      if fill_qty > order.remaining_qty
        raise "Fill qty " + fill_qty.to_s + " exceeds remaining qty " + order.remaining_qty.to_s
      end

      # Phase 4: Release Margin for the filled qty
      req_margin = Paper::Broker::MarginCalculator.calculate(
        instrument_id: order.instrument_id,
        product_type: order.product_type,
        side: order.side,
        qty: fill_qty,
        price: order.price # Using order price because that's what was blocked originally
      )
      margin_acc = MarginAccount.find_by(account_id: order.account.id)
      if margin_acc
        margin_acc.update!(
          blocked_margin: margin_acc.blocked_margin - req_margin,
          available_margin: margin_acc.available_margin + req_margin
        )
      end

      # Create the trade via TradeProcessor
      trade = TradeProcessor.execute(
        account: order.account,
        instrument: order.instrument_id,
        side: order.side,
        qty: fill_qty,
        price: fill_price,
        order: order
      )
      
      # Update Order state
      if order.remaining_qty == 0
        from_status = order.status
        order.fill!
        order.log_transition(from_status, 'FILLED', "Filled " + fill_qty.to_s + " @ " + fill_price.to_s)
      else
        from_status = order.status
        order.partial_fill! if order.OPEN?
        order.log_transition(from_status, 'PARTIALLY_FILLED', "Filled " + fill_qty.to_s + " @ " + fill_price.to_s)
      end

      trade
    end
  end
end
