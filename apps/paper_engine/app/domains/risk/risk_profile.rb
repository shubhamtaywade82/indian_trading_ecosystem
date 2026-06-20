module Risk
  class RiskProfile < ApplicationRecord
    self.table_name = "risk_profiles"
    include RuntimeScoped

    belongs_to :strategy, class_name: 'Risk::Strategy', optional: true
  end
end
