module Risk
  class RiskSnapshot < ApplicationRecord
    self.table_name = "paper_risk_snapshots"
    include RuntimeScoped

    belongs_to :strategy, class_name: 'Risk::Strategy', optional: true
  end
end
