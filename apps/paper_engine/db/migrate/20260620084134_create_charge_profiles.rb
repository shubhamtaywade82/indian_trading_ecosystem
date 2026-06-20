class CreateChargeProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :charge_profiles do |t|
      t.string :broker
      t.string :segment
      t.string :product_type
      t.decimal :stt_pct
      t.decimal :gst_pct
      t.decimal :exchange_pct
      t.decimal :sebi_pct
      t.decimal :stamp_pct
      t.decimal :brokerage_flat
      t.decimal :brokerage_pct

      t.timestamps
    end
  end
end
