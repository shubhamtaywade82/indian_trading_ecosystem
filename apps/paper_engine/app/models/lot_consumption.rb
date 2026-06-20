# frozen_string_literal: true

class LotConsumption < ApplicationRecord
  self.table_name = "lot_consumptions"

  belongs_to :trade_lot
  belongs_to :closing_trade, class_name: "PaperTrade"
end