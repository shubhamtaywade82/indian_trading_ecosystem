# frozen_string_literal: true

module Runtime
  class RuntimeConfig < ApplicationRecord
    self.table_name = "runtime_configs"

    belongs_to :runtime
  end
end
