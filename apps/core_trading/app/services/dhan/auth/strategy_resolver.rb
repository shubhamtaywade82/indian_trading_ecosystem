# frozen_string_literal: true

module Dhan
  module Auth
    class StrategyResolver
      STRATEGIES = {
        "authority" => -> { Strategies::Authority.new },
        "totp" => -> { Strategies::Totp.new },
        "manual" => -> { Strategies::Manual.new },
        "renew" => -> { Strategies::Renew.new }
      }.freeze

      def self.resolve
        mode = ENV.fetch("DHAN_AUTH_MODE", "totp").downcase.strip
        factory = STRATEGIES[mode]
        raise ArgumentError, "Unknown DHAN_AUTH_MODE: #{mode.inspect}. Valid: #{STRATEGIES.keys.join(', ')}" if factory.nil?

        factory.call
      end
    end
  end
end
