# frozen_string_literal: true

class CreatePositionTrackers < ActiveRecord::Migration[8.0]
  def change
    create_table :position_trackers do |t|
      t.string :order_no, null: false
      t.string :security_id, null: false
      t.string :segment, null: false
      t.string :instrument_type
      t.string :symbol
      t.string :side, null: false
      t.integer :quantity, null: false
      t.decimal :entry_price, precision: 16, scale: 4
      t.decimal :avg_price, precision: 16, scale: 4
      t.decimal :exit_price, precision: 16, scale: 4
      t.datetime :exited_at
      t.integer :status, null: false, default: 0
      t.boolean :paper, default: false, null: false
      t.decimal :last_pnl_rupees, precision: 16, scale: 4
      t.decimal :high_water_mark_pnl, precision: 16, scale: 4
      t.jsonb :meta, default: {}
      t.timestamps
    end

    add_index :position_trackers, :order_no, unique: true
    add_index :position_trackers, %i[security_id status]
    add_index :position_trackers, %i[paper status]
    add_index :position_trackers, :created_at
  end
end