module StrategyRuntime
  class InvestmentMandate < ApplicationRecord
    self.table_name = "investment_mandates"
    belongs_to :strategy, class_name: "StrategyRuntime::Strategy"
  end
end
