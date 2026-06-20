module Accounting
  class SettlementEngine
    def self.create_pending_settlement(trade, runtime, account)
      # Indian equity delivery is T+1
      order = trade.order
      return unless order&.product_type == 'CNC' && order&.segment == 'equity'

      # Settlement date is roughly T+1 business day. Mocking with next day.
      settlement_date = Date.today + 1.day
      
      SettlementLot.create!(
        runtime_id: runtime.id,
        account_id: account.id,
        trade_id: trade.id,
        symbol: order.symbol,
        quantity: trade.quantity,
        settlement_date: settlement_date,
        status: 'PENDING'
      )
    end

    def self.process_settlements(date = Date.today)
      lots = SettlementLot.where(status: 'PENDING').where('settlement_date <= ?', date)
      
      lots.each do |lot|
        lot.update!(status: 'SETTLED')

        Events::DomainEvent.create!(
          runtime_id: lot.runtime_id,
          event_type: 'trade.settled',
          payload: { trade_id: lot.trade_id, symbol: lot.symbol, quantity: lot.quantity },
          occurred_at: Time.current
        )
      end
    end
  end
end
