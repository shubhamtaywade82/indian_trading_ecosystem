# frozen_string_literal: true

module Dhan
  module Auth
    module Strategies
      class Manual < Base
        def call
          token = ENV["DHAN_ACCESS_TOKEN"].presence
          raise "Manual token missing: set DHAN_ACCESS_TOKEN in ENV" if token.blank?

          normalize_response(
            token: token,
            expiry: 24.hours.from_now
          )
        end
      end
    end
  end
end
