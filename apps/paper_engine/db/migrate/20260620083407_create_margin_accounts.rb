class CreateMarginAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :margin_accounts do |t|
      t.string :account_id
      t.decimal :cash_balance
      t.decimal :blocked_margin
      t.decimal :available_margin
      t.decimal :utilized_margin
      t.decimal :mtm_pnl
      t.decimal :realized_pnl

      t.timestamps
    end
  end
end
