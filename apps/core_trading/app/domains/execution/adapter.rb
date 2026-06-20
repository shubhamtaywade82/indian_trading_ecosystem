module Execution
  class Adapter
    def self.place_order(account, params)
      raise NotImplementedError, "\#{self.class} must implement place_order"
    end

    def self.modify_order(account, order_id, params)
      raise NotImplementedError, "\#{self.class} must implement modify_order"
    end

    def self.cancel_order(account, order_id)
      raise NotImplementedError, "\#{self.class} must implement cancel_order"
    end

    def self.positions(account)
      raise NotImplementedError, "\#{self.class} must implement positions"
    end

    def self.holdings(account)
      raise NotImplementedError, "\#{self.class} must implement holdings"
    end

    def self.funds(account)
      raise NotImplementedError, "\#{self.class} must implement funds"
    end

    def self.orders(account)
      raise NotImplementedError, "\#{self.class} must implement orders"
    end

    def self.trades(account)
      raise NotImplementedError, "\#{self.class} must implement trades"
    end
  end
end
