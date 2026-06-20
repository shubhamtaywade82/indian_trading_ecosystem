module Execution
  # Routes orders to the PaperEngine via HTTP or direct service call.
  # Core Trading should NOT reference PaperEngine models directly.
  # In a microservice setup this would be an HTTP client.
  # In a monorepo setup it can call PaperEngine's PlaceOrder service.
  class PaperEngineAdapter < Adapter
    def initialize(runtime_config)
      @runtime_config = runtime_config
      @account_id = runtime_config.paper_account_id
    end

    def place_order(payload)
      # In microservice: HTTP POST to paper_engine/api/orders
      # In monorepo: call PlaceOrder service directly (shared DB)
      response = paper_engine_client.post('/api/v1/orders', payload.merge(account_id: @account_id))
      parse_response(response)
    end

    def cancel_order(order_id)
      paper_engine_client.delete("/api/v1/orders/#{order_id}")
    end

    def positions
      response = paper_engine_client.get('/api/v1/positions', account_id: @account_id)
      parse_response(response)
    end

    def holdings
      response = paper_engine_client.get('/api/v1/holdings', account_id: @account_id)
      parse_response(response)
    end

    def funds
      response = paper_engine_client.get('/api/v1/funds', account_id: @account_id)
      parse_response(response)
    end

    def orders
      response = paper_engine_client.get('/api/v1/orders', account_id: @account_id)
      parse_response(response)
    end

    def trades
      response = paper_engine_client.get('/api/v1/trades', account_id: @account_id)
      parse_response(response)
    end

    private

    def paper_engine_client
      @paper_engine_client ||= PaperEngineClient.new
    end

    def parse_response(response)
      return { success: false, error: response[:error] } unless response[:success]
      response[:data]
    end
  end
end
