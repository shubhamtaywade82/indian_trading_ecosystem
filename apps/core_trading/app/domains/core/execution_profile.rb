module Core
  class ExecutionProfile < ApplicationRecord
    self.table_name = "core_execution_profiles"

    has_many :runtime_configs, class_name: "Core::RuntimeConfig", foreign_key: "core_execution_profile_id"

    validates :name, presence: true
    validates :adapter_name, presence: true
  end
end
