class MarginAccount < ApplicationRecord
  belongs_to :account, optional: true

  after_save :sync_to_ledger

  def sync_from_ledger!
    return unless account_id.present?
    
    actual_cash = LedgerEntry.where(account_id: account_id, ledger_account: 'cash').sum(:debit) - 
                  LedgerEntry.where(account_id: account_id, ledger_account: 'cash').sum(:credit)
    
    update!(
      cash_balance: actual_cash,
      available_margin: actual_cash - blocked_margin
    )
  end

  private

  def sync_to_ledger
    return unless account_id.present?
    return unless (cash_balance || 0) > 0
    
    acc = Account.find_by(id: account_id)
    return unless acc

    actual_ledger_cash = LedgerEntry.where(account_id: acc.id, ledger_account: 'cash').sum(:debit) -
                         LedgerEntry.where(account_id: acc.id, ledger_account: 'cash').sum(:credit)

    return unless actual_ledger_cash == 0

    diff = cash_balance

    JournalEntry.transaction do
      journal = JournalEntry.create!(
        account_id: acc.id,
        reference_type: 'cash_sync',
        reference_id: id || 0,
        description: "Syncing MarginAccount cash_balance to Ledger"
      )
      journal.ledger_entries.create!(account_id: acc.id, ledger_account: 'cash', debit: diff)
      journal.ledger_entries.create!(account_id: acc.id, ledger_account: 'equity', credit: diff)
    end
  end
end
