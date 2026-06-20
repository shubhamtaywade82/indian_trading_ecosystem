# frozen_string_literal: true

module DhanGateway
  class AuthManager
    RETRY_BACKOFF = 0.25

    def initialize(client_id:, access_token:)
      @client_id = client_id
      @access_token = access_token
      @mutex = Mutex.new
    end

    attr_reader :client_id, :access_token

    def refresh!
      @mutex.synchronize do
        @access_token = ENV["DHAN_ACCESS_TOKEN"] || @access_token
      end
    end

    def headers
      @mutex.synchronize do
        {
          "Content-Type" => "application/json",
          "access-token" => @access_token,
          "dhan-client-id" => @client_id
        }
      end
    end
  end
end