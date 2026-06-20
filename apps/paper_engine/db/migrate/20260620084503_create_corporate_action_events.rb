class CreateCorporateActionEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :corporate_action_events do |t|
      t.string :action_type
      t.date :ex_date
      t.string :instrument_id
      t.decimal :ratio_or_amount

      t.timestamps
    end
  end
end
