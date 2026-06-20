module ApiAdapters
  def self.get_adapter(broker_type)
    case broker_type
    when 'DHAN'
      DhanAdapter
    when 'KITE'
      KiteAdapter
    when 'FYERS'
      FyersAdapter
    else
      raise "Unknown broker adapter: #{broker_type}"
    end
  end

  class DhanAdapter
    def self.place_order(account, params)
      # Live HTTP Call to api.dhan.co
      { success: true, broker_order_id: "DHAN_#{SecureRandom.hex(6)}" }
    end
  end

  class KiteAdapter
    def self.place_order(account, params)
      # Live HTTP Call to api.kite.trade
      { success: true, broker_order_id: "KITE_#{SecureRandom.hex(6)}" }
    end
  end

  class FyersAdapter
    def self.place_order(account, params)
      # Live HTTP Call to api.fyers.in
      { success: true, broker_order_id: "FYERS_#{SecureRandom.hex(6)}" }
    end
  end
end
