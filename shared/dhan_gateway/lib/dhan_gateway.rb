# frozen_string_literal: true

require "faraday"
require "json"
require "domain_models"

require_relative "dhan_gateway/version"
require_relative "dhan_gateway/error"
require_relative "dhan_gateway/gateway_interface"
require_relative "dhan_gateway/auth_manager"
require_relative "dhan_gateway/client"
require_relative "dhan_gateway/live_gateway"
require_relative "dhan_gateway/paper_gateway"

module DhanGateway
  BASE_URL = "https://api.dhan.co"
end