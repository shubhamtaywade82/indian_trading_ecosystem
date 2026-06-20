class PlaceOrder
  def self.call(account:, payload:)
    validator = OrderValidator.new
    result = validator.call(payload)
    
    ActiveRecord::Base.transaction do
      order = PaperOrder.create!(
        account: account,
        instrument_id: payload[:instrument_id],
        side: payload[:side],
        order_type: payload[:order_type],
        product_type: payload[:product_type],
        qty: payload[:qty],
        price: payload[:price],
        trigger_price: payload[:trigger_price],
        tif: payload.fetch(:tif, 'DAY'),
        strategy_id: payload[:strategy_id],
        client_order_id: payload.fetch(:client_order_id) { SecureRandom.uuid }
      )
      
      order.log_transition(nil, 'PENDING', 'Order received')

      unless result.success?
        order.reject!
        reason = result.errors.to_h.map { |k, v| k.to_s + " " + v.join(', ') }.join("; ")
        order.log_transition('PENDING', 'REJECTED', reason)
        return order
      end

      # Phase 5: Risk Engine Check
      risk_result = Paper::Risk::PortfolioRiskEngine.evaluate(account: account, payload: payload)
      unless risk_result[:success]
        order.reject!
        order.log_transition('PENDING', 'REJECTED', risk_result[:reason])
        return order
      end

      # RMS Check Phase 4
      rms_result = Paper::Broker::RmsEngine.evaluate(
        account: account,
        instrument_id: order.instrument_id,
        product_type: order.product_type,
        side: order.side,
        qty: order.qty,
        price: order.price
      )

      if rms_result[:success]
        req_margin = rms_result[:required_margin]
        margin_acc = MarginAccount.find_by(account_id: account.id)
        margin_acc.update!(
          blocked_margin: margin_acc.blocked_margin + req_margin,
          available_margin: margin_acc.available_margin - req_margin
        )
        
        order.accept!
        order.log_transition('PENDING', 'OPEN', "Validation passed, Blocked Margin: " + req_margin.to_s)
      else
        order.reject!
        order.log_transition('PENDING', 'REJECTED', rms_result[:reason])
      end

      order
    end
  end
end
