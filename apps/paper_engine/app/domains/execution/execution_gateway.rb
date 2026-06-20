module Execution
  class ExecutionGateway
    def self.place_order(runtime, account, params)
      # 1. Broker Profile validation
      profile_check = BrokerProfiles::RuleEngine.evaluate(runtime, account, params)
      return { success: false, errors: { broker: [profile_check[:reason]] } } unless profile_check[:success]

      # 2. Check if we need to split due to Freeze Quantity
      rules = profile_check[:profile]&.rules || {}
      freeze_qty = rules['freeze_qty'].to_i
      
      orders_to_place = []
      remaining_qty = params[:quantity].to_i

      if freeze_qty > 0 && remaining_qty > freeze_qty
        Events::DomainEvent.create!(
          runtime_id: runtime.id,
          event_type: 'order.freeze_split',
          payload: { original_quantity: remaining_qty, freeze_qty: freeze_qty },
          occurred_at: Time.current
        )

        while remaining_qty > 0
          qty = [remaining_qty, freeze_qty].min
          orders_to_place << qty
          remaining_qty -= qty
        end
      else
        orders_to_place << remaining_qty
      end

      results = []
      orders_to_place.each do |qty|
        split_params = params.dup
        split_params[:quantity] = qty

        if runtime.mode == 'live'
          # Call real broker API via ApiAdapters
          results << route_to_live_broker(runtime, account, split_params)
        else
          # Paper Route
          results << OMS::CreateOrder.call(runtime: runtime, account: account, params: split_params)
        end
      end

      # For simplicity, returning the first result or aggregating
      results.first
    end

    def self.route_to_live_broker(runtime, account, params)
      profile = runtime.broker_profile
      adapter = ApiAdapters.get_adapter(profile.broker_type)
      
      response = adapter.place_order(account, params)
      
      # Mocked translation of live response to generic { success: true, order: ... }
      response
    end
  end
end
