# frozen_string_literal: true

class TradeLot < ApplicationRecord
  self.table_name = "trade_lots"

  belongs_to :account
  belongs_to :opening_trade, class_name: "PaperTrade"
  has_many :lot_consumptions, dependent: :destroy
end