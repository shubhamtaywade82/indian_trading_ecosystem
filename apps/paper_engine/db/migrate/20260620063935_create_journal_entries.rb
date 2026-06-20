class CreateJournalEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :journal_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.string :reference_type, null: false
      t.bigint :reference_id
      t.text :description
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :journal_entries, :reference_type
    add_index :journal_entries, [:reference_type, :reference_id]
  end
end
