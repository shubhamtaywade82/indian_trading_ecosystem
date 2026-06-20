module Portfolio
  class PortfolioAllocation < ApplicationRecord
    self.table_name = "portfolio_allocations"
    belongs_to :runtime
  end
end
