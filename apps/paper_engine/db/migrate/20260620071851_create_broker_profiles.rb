class CreateBrokerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :broker_profiles do |t|
      t.string :name, null: false
      t.string :broker_type, null: false
      t.string :version, null: false
      t.boolean :active, default: true
      t.jsonb :rules, default: {}

      t.timestamps
    end

    add_reference :runtimes, :broker_profile, foreign_key: true, null: true
  end
end
