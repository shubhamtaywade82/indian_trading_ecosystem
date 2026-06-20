module StrategyRuntime
  class Signal < ApplicationRecord
    self.table_name = "signals"
    belongs_to :strategy, class_name: "StrategyRuntime::Strategy"
    belongs_to :investment_mandate, class_name: "StrategyRuntime::InvestmentMandate"
  end
end
