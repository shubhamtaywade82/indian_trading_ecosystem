# frozen_string_literal: true

module DhanGateway
  class GatewayInterface
    def place_market(side:, segment:, security_id:, qty:, meta: {})
      raise NotImplementedError
    end

    def exit_market(tracker, client_order_id: nil)
      raise NotImplementedError
    end

    def wallet_snapshot
      raise NotImplementedError
    end

    def order_status(order_id)
      raise NotImplementedError
    end
  end
end