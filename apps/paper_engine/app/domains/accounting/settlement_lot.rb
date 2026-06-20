module Accounting
  class SettlementLot < ApplicationRecord
    self.table_name = "settlement_lots"
    belongs_to :trade, class_name: 'Trades::Trade'
  end
end
