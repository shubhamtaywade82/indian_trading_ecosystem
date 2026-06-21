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
      # Wrap order attributes in the :order key expected by paper_engine controller
      order_data = payload.slice(
        :instrument_id, :side, :order_type, :product_type, :qty, :price,
        :trigger_price, :tif, :strategy_id, :client_order_id
      )
      order_data[:product_type] ||= 'CNC'
      body = {
        order: order_data,
        account_id: @account_id
      }
      response = paper_engine_client.post('/api/v1/orders', body)
      parse_response(response)
    end

    def cancel_order(order_id)
      paper_engine_client.delete("/api/v1/orders/#{order_id}")
    end

    def positions
      response = paper_engine_client.get('/api/v1/positions', account_id: @account_id)
      data = parse_response(response)
      return {} unless data.is_a?(Array)

      pos_hash = {}
      data.each do |p|
        inst_id = p[:instrument_id]
        qty = p[:qty].to_i
        avg_price = p[:avg_price].to_f
        pos_hash[inst_id] = {
          qty: qty,
          value: qty * avg_price,
          avg_price: avg_price
        }
      end
      pos_hash
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
