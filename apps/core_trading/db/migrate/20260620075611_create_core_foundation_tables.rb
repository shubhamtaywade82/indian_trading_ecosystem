class CreateCoreFoundationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :core_instruments do |t|
      t.string :symbol, null: false
      t.string :exchange, null: false
      t.string :segment, null: false # NSE_EQ, NSE_FO, BSE_EQ
      t.string :instrument_type, null: false # EQ, FUT, OPT, ETF, MF
      t.string :name
      t.string :isin
      t.decimal :lot_size, default: 1.0
      t.decimal :tick_size, default: 0.05
      
      t.timestamps
    end
    add_index :core_instruments, [:symbol, :exchange], unique: true

    create_table :core_instrument_aliases do |t|
      t.references :core_instrument, null: false, foreign_key: true
      t.string :alias_name, null: false
      t.string :provider, null: false # e.g., 'dhan', 'kite'
      
      t.timestamps
    end
    add_index :core_instrument_aliases, [:alias_name, :provider], unique: true

    create_table :core_option_contracts do |t|
      t.references :core_instrument, null: false, foreign_key: true
      t.string :underlying_symbol, null: false
      t.date :expiry_date, null: false
      t.decimal :strike_price, null: false
      t.string :option_type, null: false # CE, PE
      
      t.timestamps
    end

    create_table :core_future_contracts do |t|
      t.references :core_instrument, null: false, foreign_key: true
      t.string :underlying_symbol, null: false
      t.date :expiry_date, null: false
      
      t.timestamps
    end

    create_table :core_corporate_actions do |t|
      t.references :core_instrument, null: false, foreign_key: true
      t.string :action_type, null: false # DIVIDEND, SPLIT, BONUS
      t.date :ex_date, null: false
      t.date :record_date
      t.jsonb :details, default: {}
      
      t.timestamps
    end

    create_table :core_market_data_snapshots do |t|
      t.references :core_instrument, null: false, foreign_key: true
      t.decimal :last_price
      t.decimal :volume
      t.decimal :bid
      t.decimal :ask
      t.decimal :open
      t.decimal :high
      t.decimal :low
      t.decimal :close
      t.datetime :timestamp
      
      t.timestamps
    end

    create_table :core_execution_profiles do |t|
      t.string :name, null: false
      t.string :adapter_name, null: false # PaperAdapter, DhanAdapter
      t.jsonb :capabilities, default: {}
      t.jsonb :config, default: {}
      
      t.timestamps
    end

    create_table :core_runtime_configs do |t|
      t.string :name, null: false
      t.string :mode, null: false # paper, live, backtest
      t.string :market_data_source, null: false
      t.references :core_execution_profile, foreign_key: true
      t.jsonb :settings, default: {}
      
      t.timestamps
    end
  end
end
