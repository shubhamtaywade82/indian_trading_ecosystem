# frozen_string_literal: true

class CreateSecurityMasterTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Exchanges
    create_table :exchanges do |t|
      t.string :code, null: false
      t.string :name

      t.timestamps
    end
    add_index :exchanges, :code, unique: true

    # 2. Segments
    create_table :segments do |t|
      t.references :exchange, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name

      t.timestamps
    end
    add_index :segments, :code, unique: true

    # 3. Instruments (Security Master)
    create_table :instruments do |t|
      t.bigint :security_id, null: false
      t.references :exchange, null: false, foreign_key: true
      t.references :segment, null: false, foreign_key: true
      t.string :symbol
      t.string :trading_symbol
      t.string :isin
      t.string :instrument_type
      t.string :name
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :instruments, :security_id, unique: true
    add_index :instruments, [:exchange_id, :symbol]

    # 4. Underlyings
    create_table :underlyings do |t|
      t.references :instrument, null: false, foreign_key: true
      t.string :asset_class

      t.timestamps
    end

    # 5. Derivative Contracts
    create_table :derivative_contracts do |t|
      t.references :underlying, null: false, foreign_key: true
      t.bigint :security_id, null: false
      t.date :expiry_date, null: false
      t.string :contract_type, null: false
      t.integer :lot_size
      t.decimal :tick_size, precision: 10, scale: 4

      t.timestamps
    end
    add_index :derivative_contracts, :security_id, unique: true
    add_index :derivative_contracts, [:underlying_id, :expiry_date]

    # 6. Option Contracts
    create_table :option_contracts do |t|
      t.references :derivative_contract, null: false, foreign_key: true
      t.decimal :strike_price, precision: 18, scale: 4, null: false
      t.string :option_type, null: false

      t.timestamps
    end
    add_index :option_contracts, [:strike_price, :option_type]

    # 7. Future Contracts
    create_table :future_contracts do |t|
      t.references :derivative_contract, null: false, foreign_key: true

      t.timestamps
    end

    # 8. Instrument Tokens
    create_table :instrument_tokens do |t|
      t.references :instrument, null: false, foreign_key: true
      t.string :broker, null: false
      t.string :token, null: false
      t.string :exchange_token

      t.timestamps
    end
    add_index :instrument_tokens, [:broker, :token], unique: true

    # 9. Option Chains
    create_table :option_chains do |t|
      t.references :underlying, null: false, foreign_key: true
      t.date :expiry, null: false
      t.datetime :snapshot_at, null: false

      t.timestamps
    end
    add_index :option_chains, [:underlying_id, :expiry]

    # 10. Option Chain Entries
    create_table :option_chain_entries do |t|
      t.references :option_chain, null: false, foreign_key: true
      t.references :option_contract, null: false, foreign_key: true
      t.decimal :ltp, precision: 18, scale: 4
      t.integer :oi
      t.integer :volume
      t.decimal :iv, precision: 10, scale: 6
      t.decimal :delta, precision: 10, scale: 6
      t.decimal :gamma, precision: 10, scale: 6
      t.decimal :theta, precision: 10, scale: 6
      t.decimal :vega, precision: 10, scale: 6

      t.timestamps
    end

    # 11. Candles (Persist OHLCV snapshots)
    create_table :candles do |t|
      t.bigint :security_id, null: false
      t.string :timeframe, null: false
      t.datetime :candle_time, null: false
      t.decimal :open, precision: 18, scale: 4, null: false
      t.decimal :high, precision: 18, scale: 4, null: false
      t.decimal :low, precision: 18, scale: 4, null: false
      t.decimal :close, precision: 18, scale: 4, null: false
      t.bigint :volume

      t.timestamps
    end
    add_index :candles, [:security_id, :timeframe, :candle_time], unique: true

    # 12. Watchlists
    create_table :watchlists do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :watchlists, :name, unique: true

    # 13. Watchlist Items
    create_table :watchlist_items do |t|
      t.references :watchlist, null: false, foreign_key: true
      t.references :instrument, null: false, foreign_key: true

      t.timestamps
    end
    add_index :watchlist_items, [:watchlist_id, :instrument_id], unique: true

    # 14. Instrument Imports
    create_table :instrument_imports do |t|
      t.string :source, null: false
      t.integer :total_rows
      t.integer :success_rows
      t.integer :failed_rows

      t.timestamps
    end
  end
end
