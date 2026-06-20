# frozen_string_literal: true

class Runtime::IdempotencyKey < ApplicationRecord
  self.table_name = "idempotency_keys"

  belongs_to :runtime
end
