class PositionCalculator
  def self.for(account, instrument_id)
    # Naive Phase 1 read-time aggregation based purely on trade_lots
    # Does not rely on projection tables.
    
    lots = TradeLot.where(account: account, instrument_id: instrument_id, status: 'OPEN')
    
    net_qty = lots.sum do |lot|
      lot.side == 'buy' ? lot.remaining_qty : -lot.remaining_qty
    end
    
    return { qty: 0, avg_price: 0.0 } if net_qty.zero?

    total_value = lots.sum { |lot| lot.remaining_qty * lot.entry_price }
    avg_price = total_value / net_qty.abs

    { qty: net_qty, avg_price: avg_price }
  end
end
