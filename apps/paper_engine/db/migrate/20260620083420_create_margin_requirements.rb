class CreateMarginRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :margin_requirements do |t|
      t.string :segment
      t.string :product_type
      t.string :symbol
      t.decimal :span_margin_pct
      t.decimal :exposure_margin_pct
      t.decimal :cash_requirement_pct

      t.timestamps
    end
  end
end
