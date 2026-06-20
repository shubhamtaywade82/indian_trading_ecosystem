module Paper
  module Accounting
    class SettlementEngine
      def self.handle_trade(trade)
        # Only CNC implies delivery
        return unless trade.paper_order.product_type == 'CNC'
        
        # If it's a buy, we create a SettlementLot that settles T+1
        if trade.side == 'buy'
          # T+1 logic: Ideally use a business day calculator. For now, simple Date.tomorrow
          # In real system: TradingCalendar.next_business_day(trade.exchange_ts.to_date)
          settlement_date = trade.exchange_ts.to_date + 1.day 
          
          SettlementLot.create!(
            trade_id: trade.id,
            symbol: trade.instrument_id,
            quantity: trade.fill_qty,
            settlement_date: settlement_date,
            status: 'PENDING'
          )
        elsif trade.side == 'sell'
          # If it's a sell, we need to handle delivery from existing holdings
          # For paper engine: assume holding goes away instantly or marks pending delivery out.
          # We update settled holdings or settlement lots that are PENDING to account for sale.
          qty_to_consume = trade.fill_qty
          lots = SettlementLot.where(symbol: trade.instrument_id, status: ['PENDING', 'SETTLED']).order(settlement_date: :asc)
          
          lots.each do |lot|
            break if qty_to_consume <= 0
            if lot.quantity <= qty_to_consume
              qty_to_consume -= lot.quantity
              lot.update!(quantity: 0, status: 'SOLD')
            else
              lot.update!(quantity: lot.quantity - qty_to_consume)
              qty_to_consume = 0
            end
          end
        end
      end

      # This would be run daily by a cron job or scheduled task
      def self.process_settlements!(current_date = Date.today)
        lots = SettlementLot.where(status: 'PENDING').where("settlement_date <= ?", current_date)
        
        lots.each do |lot|
          ActiveRecord::Base.transaction do
            lot.update!(status: 'SETTLED')
            
            # Post to ledger: move from Unsettled Holding to Settled Holding
            trade = PaperTrade.find(lot.trade_id)
            
            # Not strictly creating separate ledger entries for unsettled vs settled yet,
            # but this emits an event that the holding is now real.
            # In a mature system, you might have "inventory:unsettled" and "inventory:settled"
            
            # Can trigger event here
            # EventBus.publish("trade.settled", { trade_id: lot.trade_id, qty: lot.quantity })
          end
        end
      end
    end
  end
end
