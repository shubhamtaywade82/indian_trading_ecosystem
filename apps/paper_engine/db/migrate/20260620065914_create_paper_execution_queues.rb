class CreatePaperExecutionQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :paper_execution_queues do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :symbol, null: false
      t.string :side, null: false
      t.decimal :price, null: false
      t.references :order, null: false, foreign_key: true
      t.bigint :queue_position, null: false
      t.integer :remaining_quantity, null: false

      t.timestamps
    end
    add_index :paper_execution_queues, [:runtime_id, :symbol, :side, :price, :queue_position], name: 'idx_execution_queue_priority'
  end
end
