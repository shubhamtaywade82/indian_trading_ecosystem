class MatchingEngine
  # tick format: { instrument_id: 'RELIANCE', ltp: 1000, volume: 500, time: Time.current }
  def self.process_tick(tick)
    instrument = tick[:instrument_id]
    ltp = tick[:ltp]
    available_vol = tick[:volume] || 999_999_999

    # Fetch active orders for this instrument, time priority (created_at)
    orders = PaperOrder.where(instrument_id: instrument, status: ['OPEN', 'PARTIALLY_FILLED']).order(created_at: :asc)

    orders.each do |order|
      break if available_vol <= 0

      fill_qty = [order.remaining_qty, available_vol].min
      should_fill = false
      fill_price = ltp # We fill at LTP for simulation realism

      # Handle Stop Loss (SL / SL-M) trigger logic
      if %w[SL SL-M].include?(order.order_type)
        if trigger_hit?(order, ltp)
          # Convert to LIMIT or MARKET
          order.update!(order_type: order.order_type == 'SL' ? 'LIMIT' : 'MARKET')
          order.log_transition(order.status, order.status, "Stop Loss triggered at LTP " + ltp.to_s)
        else
          next # Skip if not triggered
        end
      end

      # Matching logic
      case order.order_type
      when 'MARKET'
        should_fill = true
      when 'LIMIT'
        if order.side == 'buy' && ltp <= order.price
          should_fill = true
        elsif order.side == 'sell' && ltp >= order.price
          should_fill = true
        end
      end

      if should_fill
        # Prevent fractional volume logic bugs in pure simulation context
        fill_qty = fill_qty.to_i if fill_qty == fill_qty.to_i
        
        OrderFiller.call(order: order, fill_qty: fill_qty, fill_price: fill_price)
        available_vol -= fill_qty
      end
    end
  end

  def self.trigger_hit?(order, ltp)
    if order.side == 'buy'
      ltp >= order.trigger_price
    else
      ltp <= order.trigger_price
    end
  end
end
