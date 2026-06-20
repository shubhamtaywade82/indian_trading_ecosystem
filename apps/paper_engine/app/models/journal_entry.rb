class JournalEntry < ApplicationRecord
  belongs_to :account
  has_many :ledger_entries, dependent: :destroy

  validates :reference_type, presence: true
  validates :reference_id, presence: true

  # Validates that debits == credits
  validate :must_balance

  private

  def must_balance
    total_debit = ledger_entries.sum(&:debit)
    total_credit = ledger_entries.sum(&:credit)
    errors.add(:base, "Journal entry does not balance") unless total_debit == total_credit
  end
end
