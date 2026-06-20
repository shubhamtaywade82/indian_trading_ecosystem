# frozen_string_literal: true

module DhanGateway
  class Error < StandardError; end
  class AuthError < Error; end
  class TimeoutError < Error; end
  class RateLimitError < Error; end
  class OrderRejected < Error; end
  class InsufficientFunds < Error; end
end