module Execution
  # HTTP client for calling the Paper Engine API.
  # Core Trading communicates with Paper Engine only through this boundary.
  class PaperEngineClient
    BASE_URL = ENV.fetch('PAPER_ENGINE_URL', 'http://localhost:3001')

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri)
      attach_headers!(request)

      response = http.request(request)
      parse(response)
    rescue StandardError => e
      { success: false, error: e.message }
    end

    def post(path, body = {})
      uri = URI("#{BASE_URL}#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      request = Net::HTTP::Post.new(uri)
      attach_headers!(request)
      request.body = body.to_json

      response = http.request(request)
      parse(response)
    rescue StandardError => e
      { success: false, error: e.message }
    end

    def delete(path)
      uri = URI("#{BASE_URL}#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      request = Net::HTTP::Delete.new(uri)
      attach_headers!(request)

      response = http.request(request)
      parse(response)
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    def attach_headers!(request)
      request['Content-Type']  = 'application/json'
      request['Accept']        = 'application/json'
      request['X-Api-Version'] = 'v1'
    end

    def parse(response)
      body = JSON.parse(response.body, symbolize_names: true)
      success = response.code.to_i < 400
      { success: success, data: body, status_code: response.code.to_i }
    rescue JSON::ParserError
      { success: false, error: "Non-JSON response: #{response.body}" }
    end
  end
end
