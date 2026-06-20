# frozen_string_literal: true

class Runtime::RuntimeConfig < ApplicationRecord
  self.table_name = "runtime_configs"

  belongs_to :runtime
end
