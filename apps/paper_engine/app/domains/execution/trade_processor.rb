module Execution
  class TradeProcessor
    def self.process(order, executed_at: Time.current)
      Trades::Trade.transaction do
        trade = Trades::Trade.create!(
          runtime: order.runtime,
          order: order,
          symbol: order.symbol,
          side: order.side,
          quantity: order.quantity,
          price: order.price,
          trade_value: order.quantity * order.price,
          executed_at: executed_at
        )

        Accounting::LedgerEngine.process(trade)

        Events::DomainEvent.create!(
          runtime: order.runtime,
          event_type: "trade.executed",
          payload: { trade_id: trade.id },
          occurred_at: Time.current
        )

        Events::DomainEvent.create!(
          runtime: order.runtime,
          event_type: "ledger.posted",
          payload: { reference_type: "Trade", reference_id: trade.id },
          occurred_at: Time.current
        )

        Projections::PositionProjector.call(trade)
        Projections::FundsProjector.call(trade)
        Projections::HoldingProjector.call(trade)

        trade
      end
    end
  end
end
