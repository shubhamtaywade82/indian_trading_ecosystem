# frozen_string_literal: true

module Runtime
  class IdempotencyKey < ApplicationRecord
    self.table_name = "idempotency_keys"

    belongs_to :runtime
  end
end
