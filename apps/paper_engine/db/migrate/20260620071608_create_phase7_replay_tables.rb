class CreatePhase7ReplayTables < ActiveRecord::Migration[8.1]
  def change
    create_table :replay_sessions do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :status, default: 'PENDING'
      t.string :mode, default: 'TICK'
      t.datetime :current_time
      t.datetime :start_time
      t.datetime :end_time
      t.string :slippage_model, default: 'DEPTH_BASED'
      t.string :latency_model, default: 'NONE'
      t.string :spread_model, default: 'HISTORICAL'

      t.timestamps
    end

    add_column :runtimes, :slippage_model, :string, default: 'DEPTH_BASED'
    add_column :runtimes, :latency_model, :string, default: 'NONE'
    add_column :runtimes, :spread_model, :string, default: 'HISTORICAL'
    add_column :runtimes, :replay_mode, :string, default: 'TICK'
  end
end
