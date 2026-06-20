# frozen_string_literal: true

module Dhan
  module Auth
    module Strategies
      class Base
        def call
          raise NotImplementedError, "#{self.class}#call is not implemented"
        end

        private

        def normalize_response(token:, expiry:)
          {
            access_token: token,
            expiry_time: expiry
          }
        end
      end
    end
  end
end
