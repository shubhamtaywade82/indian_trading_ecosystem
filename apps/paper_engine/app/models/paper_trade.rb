# frozen_string_literal: true

class PaperTrade < ApplicationRecord
  self.table_name = "paper_trades"

  belongs_to :account
  belongs_to :paper_order
end