class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :tenant_id, null: false
      t.string :name, null: false
      t.string :mode, null: false
      t.string :run_id
      t.string :currency, null: false
      t.decimal :starting_balance, precision: 16, scale: 4, default: 0.0

      t.timestamps
    end

    add_index :accounts, :tenant_id
    add_index :accounts, :run_id
  end
end
