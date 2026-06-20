# frozen_string_literal: true

require "timeout"

module DhanGateway
  class Client
    def initialize(client_id:, access_token:)
      @auth = AuthManager.new(client_id: client_id, access_token: access_token)
    end

    def connection
      @connection ||= Faraday.new(url: DhanGateway::BASE_URL) do |f|
        f.headers = @auth.headers
        f.response :json
        f.adapter Faraday.default_adapter
      end
    end

    def get(path, params = {})
      with_retry_auth do
        response = connection.get(path, params)
        parse_response(response)
      end
    end

    def post(path, body = {})
      with_retry_auth do
        response = connection.post(path, body.to_json)
        parse_response(response)
      end
    end

    def wallet
      result = get("/fundlimit")
      return nil if result.nil?

      {
        cash: result["availabelBalance"].to_f,
        utilized: result["utilizedAmount"].to_f,
        exposure: result["collateral"].to_f,
        margin: result["availabelBalance"].to_f + result["openingBalance"].to_f
      }
    end

    def place_order(payload)
      result = post("/orders", payload)
      { success: true, order_id: result["orderId"], status: result["orderStatus"] }
    rescue Error => e
      { success: false, error: e.message }
    end

    private

    def parse_response(response)
      case response.status
      when 200..299
        response.body
      when 401
        raise AuthError, "Unauthorized - token may be expired"
      when 429
        raise RateLimitError, "Rate limited: #{response.body}"
      when 400
        parsed = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
        if parsed["errorMessage"]&.match?(/insufficient/i)
          raise InsufficientFunds, parsed["errorMessage"]
        elsif parsed["errorMessage"]&.match?(/rejected/i)
          raise OrderRejected, parsed["errorMessage"]
        end
        raise Error, parsed["errorMessage"] || "Request failed"
      else
        raise Error, "HTTP #{response.status}: #{response.body}"
      end
    end

    def with_retry_auth(max_retries: 3)
      retries = 0
      begin
        yield
      rescue AuthError
        if retries < max_retries
          @auth.refresh!
          retries += 1
          sleep(RETRY_BACKOFF * retries)
          retry
        end
        raise
      rescue RateLimitError
        if retries < max_retries
          retries += 1
          sleep(5.0 * retries)
          retry
        end
        raise
      rescue Timeout::Error, SocketError, Errno::ECONNREFUSED => e
        if retries < max_retries
          retries += 1
          sleep(RETRY_BACKOFF * retries)
          retry
        end
        raise TimeoutError, "Max retries exceeded: #{e.message}"
      end
    end
  end
end