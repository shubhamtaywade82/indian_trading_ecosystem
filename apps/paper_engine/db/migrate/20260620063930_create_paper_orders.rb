class CreatePaperOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :paper_orders do |t|
      t.references :account, null: false, foreign_key: true
      t.string :instrument_id, null: false
      t.string :side, null: false
      t.string :order_type, null: false
      t.string :product_type, null: false
      t.integer :qty, null: false
      t.decimal :price, precision: 16, scale: 4
      t.decimal :trigger_price, precision: 16, scale: 4
      t.string :tif, null: false
      t.string :status, null: false
      t.string :client_order_id

      t.timestamps
    end

    add_index :paper_orders, :instrument_id
    add_index :paper_orders, :status
    add_index :paper_orders, :client_order_id
  end
end
