module StrategyRuntime
  class Strategy < ApplicationRecord
    self.table_name = "strategies"
    has_many :investment_mandates, class_name: "StrategyRuntime::InvestmentMandate"
    has_many :signals, class_name: "StrategyRuntime::Signal"
  end
end
