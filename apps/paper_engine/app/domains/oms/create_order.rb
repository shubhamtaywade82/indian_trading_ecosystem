module OMS
  class CreateOrder
    def self.call(runtime:, account:, params:)
      validation = OrderValidator.validate(params.to_h)
      return { success: false, errors: validation[:errors] } unless validation[:valid]

      rms_check = Broker::RMSEngine.evaluate(runtime, account, params)
      if !rms_check[:success]
        Events::DomainEvent.create!(
          runtime: runtime,
          event_type: 'order.rejected',
          payload: { reason: rms_check[:reason] },
          occurred_at: Time.current
        )
        return { success: false, errors: { rms: [rms_check[:reason]] } }
      end

      order = Orders::Order.create!(
        runtime: runtime,
        account: account,
        symbol: params[:symbol],
        side: params[:side],
        quantity: params[:quantity],
        order_type: params[:order_type],
        price: params[:price] || 0.0,
        trigger_price: params[:trigger_price],
        product_type: params[:product_type],
        external_order_id: SecureRandom.uuid,
        status: 'pending'
      )

      order.accept!

      Events::DomainEvent.create!(
        runtime: runtime,
        event_type: 'order.created',
        payload: { order_id: order.id },
        occurred_at: Time.current
      )

      Events::DomainEvent.create!(
        runtime: runtime,
        event_type: 'order.accepted',
        payload: { order_id: order.id },
        occurred_at: Time.current
      )

      # Trigger Exchange Simulation & Matching Engine (Phase 3)
      Execution::ExecutionEngine.execute(order)

      { success: true, order: order }
    end
  end
end
