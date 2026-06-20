class CreatePortfolioCashflows < ActiveRecord::Migration[8.1]
  def change
    create_table :portfolio_cashflows do |t|
      t.bigint :account_id
      t.string :flow_type
      t.decimal :amount
      t.string :reference_type
      t.string :reference_id

      t.timestamps
    end
  end
end
