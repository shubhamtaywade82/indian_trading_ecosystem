module Core
  class RuntimeConfig < ApplicationRecord
    self.table_name = "core_runtime_configs"

    belongs_to :execution_profile, class_name: "Core::ExecutionProfile", foreign_key: "core_execution_profile_id", optional: true

    validates :name, presence: true
    validates :mode, presence: true, inclusion: { in: %w[paper live backtest] }
    validates :market_data_source, presence: true
  end
end
