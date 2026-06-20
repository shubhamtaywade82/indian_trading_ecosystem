class LedgerPoster
  def self.post_trade!(account:, trade:)
    value = trade.fill_value
    instrument = trade.instrument_id

    JournalEntry.transaction do
      journal = JournalEntry.create!(
        account: account,
        reference_type: 'trade',
        reference_id: trade.id,
        description: "Trade execution for " + instrument
      )

      if trade.side == 'buy'
        journal.ledger_entries.create!(account: account, ledger_account: "inventory:" + instrument, debit: value)
        journal.ledger_entries.create!(account: account, ledger_account: "cash", credit: value)
      else
        journal.ledger_entries.create!(account: account, ledger_account: "cash", debit: value)
        journal.ledger_entries.create!(account: account, ledger_account: "inventory:" + instrument, credit: value)
      end
    end
  end
end
