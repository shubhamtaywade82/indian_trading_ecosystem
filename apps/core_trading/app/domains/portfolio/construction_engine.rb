module Portfolio
  class ConstructionEngine
    # Compares target positions with current positions and generates Execution Orders
    def self.generate_orders(target_positions, current_positions, mandate = nil)
      orders = []
      
      # 1. Identify sells first (to free up capital)
      current_positions.each do |instrument, current_qty|
        target_qty = target_positions[instrument] || 0
        
        if current_qty > target_qty
          qty_to_sell = current_qty - target_qty
          orders << {
            instrument_id: instrument,
            side: 'sell',
            qty: qty_to_sell,
            order_type: 'MARKET',
            priority: 1 # High priority to sell first
          }
        end
      end

      # 2. Identify buys
      target_positions.each do |instrument, target_qty|
        current_qty = current_positions[instrument] || 0
        
        if target_qty > current_qty
          qty_to_buy = target_qty - current_qty
          orders << {
            instrument_id: instrument,
            side: 'buy',
            qty: qty_to_buy,
            order_type: 'MARKET',
            priority: 2 # Lower priority, execute after sells
          }
        end
      end
      
      # Sort orders by priority so sells happen before buys
      orders.sort_by! { |o| o[:priority] }
      
      orders
    end
  end
end
