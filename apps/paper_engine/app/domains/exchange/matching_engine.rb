module Exchange
  class MatchingEngine
    def self.match_new_order(order)
      book = OrderBook.for(order.runtime_id, order.symbol)
      remaining_qty = order.quantity - order.filled_quantity

      trades = []

      # Try to fill against top of book immediately
      if order.side == 'BUY'
        if order.order_type == 'MARKET' || (order.order_type == 'LIMIT' && order.price >= book.ask_price)
          # Can fill
          fill_price = book.ask_price > 0 ? book.ask_price : (book.ltp > 0 ? book.ltp : order.price)
          fill_qty = order.order_type == 'MARKET' ? remaining_qty : book.consume_ask_qty(remaining_qty)
          
          if fill_qty > 0
            trades << { quantity: fill_qty, price: fill_price }
            remaining_qty -= fill_qty
          end
        end
      elsif order.side == 'SELL'
        if order.order_type == 'MARKET' || (order.order_type == 'LIMIT' && order.price <= book.bid_price)
          # Can fill
          fill_price = book.bid_price > 0 ? book.bid_price : (book.ltp > 0 ? book.ltp : order.price)
          fill_qty = order.order_type == 'MARKET' ? remaining_qty : book.consume_bid_qty(remaining_qty)

          if fill_qty > 0
            trades << { quantity: fill_qty, price: fill_price }
            remaining_qty -= fill_qty
          end
        end
      end

      # If IOC, remaining qty is cancelled, don't queue
      if remaining_qty > 0
        if order.validity == 'IOC' || order.order_type == 'MARKET'
          # Cancel remainder
        else
          # Queue limit order
          queue_order(order, remaining_qty)
        end
      end

      { trades: trades, remaining_qty: remaining_qty }
    end

    def self.process_rested_orders(runtime_id, symbol)
      book = OrderBook.for(runtime_id, symbol)

      Execution::QueueEntry.transaction do
        # Match BUY limit orders against ASK
        if book.ask_qty > 0 && book.ask_price > 0
          Execution::QueueEntry.where(runtime_id: runtime_id, symbol: symbol).matching_buys(book.ask_price).lock("FOR UPDATE SKIP LOCKED").find_each do |entry|
            fill_qty = book.consume_ask_qty(entry.remaining_quantity)
            break if fill_qty == 0

            create_trade_and_update(entry, fill_qty, book.ask_price)
          end
        end

        # Match SELL limit orders against BID
        if book.bid_qty > 0 && book.bid_price > 0
          Execution::QueueEntry.where(runtime_id: runtime_id, symbol: symbol).matching_sells(book.bid_price).lock("FOR UPDATE SKIP LOCKED").find_each do |entry|
            fill_qty = book.consume_bid_qty(entry.remaining_quantity)
            break if fill_qty == 0

            create_trade_and_update(entry, fill_qty, book.bid_price)
          end
        end
      end
    end

    private

    def self.queue_order(order, remaining_qty)
      last_pos = Execution::QueueEntry.where(runtime_id: order.runtime_id, symbol: order.symbol, side: order.side, price: order.price).maximum(:queue_position) || 0
      
      Execution::QueueEntry.create!(
        runtime_id: order.runtime_id,
        symbol: order.symbol,
        side: order.side,
        price: order.price,
        order_id: order.id,
        remaining_quantity: remaining_qty,
        queue_position: last_pos + 1
      )
      
      Events::DomainEvent.create!(
        runtime_id: order.runtime_id,
        event_type: "order.queued",
        payload: { order_id: order.id, remaining_qty: remaining_qty },
        occurred_at: Time.current
      )
    end

    def self.create_trade_and_update(entry, fill_qty, fill_price)
      order = entry.order
      
      # We just trigger ExecutionEngine directly for rested orders
      Execution::ExecutionEngine.process_trade(order, fill_qty, fill_price)

      entry.remaining_quantity -= fill_qty
      if entry.remaining_quantity <= 0
        entry.destroy!
      else
        entry.save!
      end
    end
  end
end
