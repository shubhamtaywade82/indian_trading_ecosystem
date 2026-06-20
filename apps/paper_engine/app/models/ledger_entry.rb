class LedgerEntry < ApplicationRecord
  belongs_to :account
  belongs_to :journal_entry

  validates :ledger_account, presence: true
  validates :debit, numericality: { greater_than_or_equal_to: 0 }
  validates :credit, numericality: { greater_than_or_equal_to: 0 }

  def self.balance_for(account, ledger_account_name)
    where(account: account, ledger_account: ledger_account_name).sum('debit - credit')
  end
end
