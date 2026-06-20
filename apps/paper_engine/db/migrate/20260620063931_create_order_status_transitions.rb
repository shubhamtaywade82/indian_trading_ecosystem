class CreateOrderStatusTransitions < ActiveRecord::Migration[8.1]
  def change
    create_table :order_status_transitions do |t|
      t.references :paper_order, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.text :reason
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :order_status_transitions, :to_status
  end
end
