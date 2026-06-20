# frozen_string_literal: true

require 'securerandom'

module Execution
  class DhanAdapter < Adapter
    def initialize(runtime_config)
      @runtime_config = runtime_config
    end

    def place_order(payload)
      instrument = resolve_instrument(payload[:instrument_id])
      unless instrument
        return { success: false, error: "Instrument not found for ID: #{payload[:instrument_id]}" }
      end

      side = payload[:side].to_s.upcase
      qty = payload[:qty] || payload[:quantity]
      order_type = payload[:order_type] || (payload[:price] ? "LIMIT" : "MARKET")
      product_type = payload[:product_type] || "INTRADAY"
      price = payload[:price]

      exch_seg = instrument.segment.code.upcase
      exch_seg = "IDX_I" if exch_seg == "INDEX" || exch_seg == "IDX"

      client_order_id = payload[:client_order_id] || "CORE-#{side[0]}-#{instrument.security_id}-#{Time.now.strftime('%d%H%M%S')}-#{SecureRandom.hex(2)}"
      # DhanHQ correlation ID limit is 30 characters
      client_order_id = client_order_id[0..29]

      dhan_payload = {
        transaction_type: side,
        exchange_segment: exch_seg,
        security_id: instrument.security_id.to_s,
        quantity: qty.to_i,
        order_type: order_type,
        product_type: product_type,
        validity: "DAY",
        disclosed_quantity: 0,
        correlation_id: client_order_id
      }

      dhan_payload[:price] = price.to_f if order_type == "LIMIT"

      begin
        order = DhanHQ::Models::Order.create(dhan_payload)
        if order
          order_id = order.respond_to?(:order_id) ? order.order_id : (order['order_id'] || order[:order_id])
          order_status = order.respond_to?(:order_status) ? order.order_status : (order['order_status'] || order[:order_status] || "ACCEPTED")
          { success: true, order_id: order_id, status: order_status, client_order_id: client_order_id }
        else
          { success: false, error: "Failed to create order via DhanHQ" }
        end
      rescue => e
        Rails.logger.error("[Execution::DhanAdapter] Order placement failed: #{e.message}")
        { success: false, error: e.message }
      end
    end

    def modify_order(account, order_id, params)
      # In real implementation: update order parameters
      raise NotImplementedError, "Execution::DhanAdapter does not yet support modify_order"
    end

    def cancel_order(order_id)
      begin
        order = DhanHQ::Models::Order.find(order_id)
        if order
          order.cancel
          { success: true }
        else
          { success: false, error: "Order not found" }
        end
      rescue => e
        Rails.logger.error("[Execution::DhanAdapter] Order cancel failed for #{order_id}: #{e.message}")
        { success: false, error: e.message }
      end
    end

    def positions
      raw_positions = DhanHQ::Models::Position.active || []
      pos_hash = Hash.new(0)
      raw_positions.each do |pos|
        sec_id = pos.respond_to?(:security_id) ? pos.security_id : (pos['security_id'] || pos[:security_id])
        net_qty = pos.respond_to?(:net_qty) ? pos.net_qty : (pos['net_qty'] || pos[:net_qty] || 0)
        
        instrument = Instrument.find_by(security_id: sec_id)
        symbol = instrument ? instrument.symbol : sec_id.to_s
        pos_hash[symbol] += net_qty.to_i
      end
      pos_hash
    rescue => e
      Rails.logger.error("[Execution::DhanAdapter] Failed to fetch positions: #{e.message}")
      {}
    end

    def holdings
      []
    end

    def funds
      funds_obj = DhanHQ::Models::Funds.fetch
      available = if funds_obj.respond_to?(:available_balance)
                    funds_obj.available_balance.to_f
                  elsif funds_obj.is_a?(Hash)
                    (funds_obj['availabelBalance'] || funds_obj[:available_balance] || funds_obj['available_balance'] || 0).to_f
                  else
                    0.0
                  end
      { available: available }
    rescue => e
      Rails.logger.error("[Execution::DhanAdapter] Failed to fetch funds: #{e.message}")
      { available: 0.0 }
    end

    def orders
      if defined?(DhanHQ::Models::Order) && DhanHQ::Models::Order.respond_to?(:all)
        DhanHQ::Models::Order.all || []
      else
        []
      end
    rescue => e
      Rails.logger.error("[Execution::DhanAdapter] Failed to fetch orders: #{e.message}")
      []
    end

    def trades
      []
    end

    private

    def resolve_instrument(symbol_or_id)
      if symbol_or_id.is_a?(Instrument)
        symbol_or_id
      elsif symbol_or_id.to_s.match?(/\A\d+\z/)
        Instrument.find_by(security_id: symbol_or_id) || Instrument.find_by(id: symbol_or_id)
      else
        Instrument.find_by(symbol: symbol_or_id) || Instrument.find_by(trading_symbol: symbol_or_id)
      end
    end
  end
end
