# frozen_string_literal: true

class PaperOrder < ApplicationRecord
  self.table_name = "paper_orders"

  belongs_to :account
  has_many :paper_trades, dependent: :destroy
  has_many :order_status_transitions, dependent: :destroy
end