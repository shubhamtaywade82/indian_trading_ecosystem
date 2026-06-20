class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :journal_entry, null: false, foreign_key: true
      t.string :ledger_account, null: false
      t.decimal :debit, precision: 16, scale: 4, default: 0.0
      t.decimal :credit, precision: 16, scale: 4, default: 0.0

      t.timestamps
    end

    add_index :ledger_entries, :ledger_account
  end
end
