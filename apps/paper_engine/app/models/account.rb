class Account < ApplicationRecord
  has_many :paper_orders
  has_many :paper_trades
  has_many :journal_entries
  has_many :ledger_entries

  validates :tenant_id, presence: true
  validates :mode, presence: true, inclusion: { in: %w[paper backtest] }
  validates :name, presence: true
end
