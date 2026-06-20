class CreateBrokerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :broker_profiles do |t|
      t.string :broker_name
      t.boolean :supports_amo
      t.integer :max_order_qty
      t.boolean :block_penny_stocks
      t.boolean :restrict_illiquid_options
      t.string :error_format

      t.timestamps
    end
  end
end
