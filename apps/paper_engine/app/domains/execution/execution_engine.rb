module Execution
  class ExecutionEngine
    def self.execute(order)
      Orders::Order.transaction do
        # Lock order
        order.lock!

        # Match
        result = Exchange::MatchingEngine.match_new_order(order)
        
        result[:trades].each do |trade_data|
          process_trade(order, trade_data[:quantity], trade_data[:price])
        end

        if order.validity == 'IOC' && result[:remaining_qty] > 0
          # Cancel remainder
          order.update!(status: 'cancelled')
          Events::DomainEvent.create!(
            runtime: order.runtime,
            event_type: 'order.cancelled',
            payload: { order_id: order.id, reason: 'IOC partial fill' },
            occurred_at: Time.current
          )
        end
      end
    end

    def self.process_trade(order, fill_qty, fill_price)
      order.lock! if order.persisted? # re-lock if called from background tick
      
      trade_value = fill_qty * fill_price

      trade = Trades::Trade.create!(
        runtime_id: order.runtime_id,
        order_id: order.id,
        symbol: order.symbol,
        side: order.side,
        quantity: fill_qty,
        price: fill_price,
        trade_value: trade_value,
        executed_at: Time.current
      )

      # Ledger
      Accounting::LedgerEngine.process(trade)

      # Phase 6: Charges and Settlement
      Accounting::ChargesEngine.post_charges(trade, order.runtime, order.account)
      Accounting::SettlementEngine.create_pending_settlement(trade, order.runtime, order.account)

      # Update Order state
      new_filled = order.filled_quantity + fill_qty
      total_value = (order.filled_quantity * (order.average_price || 0)) + trade_value
      avg_price = total_value / new_filled
      
      status = new_filled >= order.quantity ? 'filled' : 'partially_filled'
      
      order.update!(
        filled_quantity: new_filled,
        average_price: avg_price,
        status: status
      )

      # Projections
      Projections::PositionProjector.call(trade)
      Projections::FundsProjector.call(trade)
      Projections::HoldingProjector.call(trade)

      # Events
      Events::DomainEvent.create!(
        runtime_id: order.runtime_id,
        event_type: "trade.matched",
        payload: { order_id: order.id, trade_id: trade.id },
        occurred_at: Time.current
      )

      Events::DomainEvent.create!(
        runtime_id: order.runtime_id,
        event_type: "trade.executed",
        payload: { trade_id: trade.id },
        occurred_at: Time.current
      )

      Events::DomainEvent.create!(
        runtime_id: order.runtime_id,
        event_type: "ledger.posted",
        payload: { reference_type: "Trade", reference_id: trade.id },
        occurred_at: Time.current
      )

      trade
    end
  end
end
