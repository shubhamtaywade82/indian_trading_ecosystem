# frozen_string_literal: true

require "securerandom"

module DhanGateway
  class PaperGateway < GatewayInterface
    def initialize(wallet: nil)
      @wallet = wallet || default_wallet
    end

    def place_market(side:, segment:, security_id:, qty:, meta: {})
      order_no = meta[:client_order_id] || "PAPER-#{SecureRandom.hex(4)}"

      DomainModels::Commands::CommandResult.success(payload: {
        success: true,
        order_id: order_no,
        client_order_id: order_no,
        status: :accepted,
        paper: true
      })
    rescue StandardError => e
      DomainModels::Commands::CommandResult.failure(error: e.message)
    end

    def exit_market(tracker, client_order_id: nil)
      exit_price = tracker.meta.dig("last_ltp") || tracker.entry_price
      coid = client_order_id || "PAPER-EXIT-#{SecureRandom.hex(4)}"

      DomainModels::Commands::CommandResult.success(payload: {
        success: true,
        order_id: coid,
        client_order_id: coid,
        status: :accepted,
        exit_price: exit_price,
        paper: true
      })
    rescue StandardError => e
      DomainModels::Commands::CommandResult.failure(error: e.message)
    end

    def wallet_snapshot
      @wallet
    end

    def order_status(order_id)
      { order_id: order_id, status: "COMPLETE" }
    end

    private

    def default_wallet
      { cash: 100_000, equity: 100_000, utilized: 0, exposure: 0, margin: 100_000, mtm: 0 }
    end
  end
end