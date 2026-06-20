# frozen_string_literal: true

class Account < ApplicationRecord
  self.table_name = "accounts"

  has_many :paper_orders, dependent: :destroy
  has_many :paper_trades, dependent: :destroy
  has_many :trade_lots, dependent: :destroy
  has_many :journal_entries, dependent: :destroy
  has_many :ledger_entries, dependent: :destroy
end