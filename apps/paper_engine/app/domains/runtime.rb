class Runtime < ApplicationRecord
  enum :mode,
  {
    paper: "paper",
    backtest: "backtest",
    replay: "replay"
  }

  has_many :accounts
  has_one :runtime_config
  has_many :orders
  has_many :trades
  has_many :ledger_entries
  has_many :domain_events
  has_many :idempotency_keys
end
