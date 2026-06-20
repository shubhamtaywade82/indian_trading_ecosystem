# frozen_string_literal: true

require "securerandom"

module DhanGateway
  class LiveGateway < GatewayInterface
    def initialize(client:)
      @client = client
    end

    def place_market(side:, segment:, security_id:, qty:, meta: {})
      coid = meta[:client_order_id] || generate_coid(side, security_id)

      payload = {
        dhanClientId: @client.instance_variable_get(:@auth).client_id,
        correlationId: coid,
        transactionType: side.to_s.upcase,
        exchangeSegment: map_segment(segment),
        productType: meta[:product_type] || "INTRADAY",
        orderType: "MARKET",
        securityId: security_id,
        quantity: qty,
        price: 0
      }

      result = @client.place_order(payload)
      return DomainModels::Commands::CommandResult.failure(error: result[:error]) unless result[:success]

      DomainModels::Commands::CommandResult.success(payload: {
        order_id: result[:order_id],
        client_order_id: coid,
        status: :accepted,
        paper: false
      })
    rescue StandardError => e
      DomainModels::Commands::CommandResult.failure(error: e.message, reason: "broker_error")
    end

    def exit_market(tracker, client_order_id: nil)
      coid = client_order_id || "EXIT-#{tracker.security_id}-#{SecureRandom.hex(4)}"

      payload = {
        dhanClientId: @client.instance_variable_get(:@auth).client_id,
        correlationId: coid,
        transactionType: tracker.side.to_s.downcase == "buy" ? "SELL" : "BUY",
        exchangeSegment: map_segment(tracker.segment),
        productType: tracker.meta.dig("product_type") || "INTRADAY",
        orderType: "MARKET",
        securityId: tracker.security_id,
        quantity: tracker.quantity,
        price: 0
      }

      result = @client.place_order(payload)
      return DomainModels::Commands::CommandResult.failure(error: result[:error]) unless result[:success]

      DomainModels::Commands::CommandResult.success(payload: {
        order_id: result[:order_id],
        client_order_id: coid,
        status: :accepted,
        exit_price: nil,
        paper: false
      })
    rescue StandardError => e
      DomainModels::Commands::CommandResult.failure(error: e.message, reason: "broker_error")
    end

    def wallet_snapshot
      wallet = @client.wallet
      return default_wallet unless wallet

      {
        cash: wallet[:cash],
        equity: wallet[:cash],
        utilized: wallet[:utilized],
        exposure: wallet[:exposure],
        margin: wallet[:margin],
        mtm: 0
      }
    rescue StandardError => e
      default_wallet
    end

    def order_status(order_id)
      result = @client.get("/orders/#{order_id}")
      result.is_a?(Hash) ? result : {}
    end

    private

    def generate_coid(side, security_id)
      "#{side.upcase[0]}-#{security_id}-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{SecureRandom.hex(2)}"
    end

    def map_segment(segment)
      case segment.to_s.upcase
      when "NSE_FNO" then "NSE_FNO"
      when "NSE_EQ" then "NSE_EQ"
      when "BSE_FNO" then "BSE_FNO"
      else segment.to_s.upcase
      end
    end

    def default_wallet
      { cash: 0, equity: 0, utilized: 0, exposure: 0, margin: 0, mtm: 0 }
    end
  end
end