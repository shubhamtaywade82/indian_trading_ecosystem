# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Security Master & Instrument Persistency", type: :model do
  let!(:nse) { Exchange.create!(code: "NSE", name: "National Stock Exchange") }
  let!(:nse_eq) { Segment.create!(exchange: nse, code: "NSE_EQ", name: "NSE Equity Cash") }
  let!(:nse_fno) { Segment.create!(exchange: nse, code: "NSE_FNO", name: "NSE Futures & Options") }

  let!(:reliance) do
    Instrument.create!(
      security_id: 3045,
      exchange: nse,
      segment: nse_eq,
      symbol: "RELIANCE",
      trading_symbol: "RELIANCE-EQ",
      isin: "INE002A01018",
      instrument_type: :equity,
      name: "Reliance Industries Limited"
    )
  end

  let!(:nifty) do
    Instrument.create!(
      security_id: 13,
      exchange: nse,
      segment: nse_fno,
      symbol: "NIFTY",
      trading_symbol: "Nifty 50",
      instrument_type: :index,
      name: "Nifty 50 Index"
    )
  end

  let!(:reliance_underlying) do
    Underlying.create!(instrument: reliance, asset_class: "Equity")
  end

  let!(:nifty_underlying) do
    Underlying.create!(instrument: nifty, asset_class: "Index")
  end

  it "establishes correct associations for the security master" do
    expect(reliance.exchange).to eq(nse)
    expect(reliance.segment).to eq(nse_eq)
    expect(nse.instruments).to include(reliance)
    expect(nse_eq.instruments).to include(reliance)
  end

  it "stores broker tokens separate from core instruments" do
    token = InstrumentToken.create!(instrument: reliance, broker: "dhan", token: "3045", exchange_token: "3045")
    expect(reliance.instrument_tokens).to include(token)
    expect(InstrumentToken.find_by(broker: "dhan", token: "3045").instrument).to eq(reliance)
  end

  describe "Derivative and Option Contract layout" do
    let!(:nifty_fut_derivative) do
      DerivativeContract.create!(
        underlying: nifty_underlying,
        security_id: 45001,
        expiry_date: Date.current.end_of_month,
        contract_type: "future",
        lot_size: 50,
        tick_size: 0.05
      )
    end

    let!(:nifty_fut) do
      FutureContract.create!(derivative_contract: nifty_fut_derivative)
    end

    let!(:nifty_opt_derivative) do
      DerivativeContract.create!(
        underlying: nifty_underlying,
        security_id: 45002,
        expiry_date: Date.current.end_of_month,
        contract_type: "call_option",
        lot_size: 50,
        tick_size: 0.05
      )
    end

    let!(:nifty_ce) do
      OptionContract.create!(
        derivative_contract: nifty_opt_derivative,
        strike_price: 25000.0,
        option_type: "CE"
      )
    end

    it "resolves derivative contract details cleanly" do
      expect(nifty_fut_derivative.future_contract).to eq(nifty_fut)
      expect(nifty_opt_derivative.option_contract).to eq(nifty_ce)
      expect(nifty_underlying.derivative_contracts).to include(nifty_fut_derivative, nifty_opt_derivative)
    end
  end

  describe "Option Chains & Greek Snapshots" do
    let!(:chain) do
      OptionChain.create!(
        underlying: nifty_underlying,
        expiry: Date.current.end_of_month,
        snapshot_at: Time.current
      )
    end

    let!(:nifty_opt_derivative) do
      DerivativeContract.create!(
        underlying: nifty_underlying,
        security_id: 45002,
        expiry_date: Date.current.end_of_month,
        contract_type: "call_option",
        lot_size: 50,
        tick_size: 0.05
      )
    end

    let!(:nifty_ce) do
      OptionContract.create!(
        derivative_contract: nifty_opt_derivative,
        strike_price: 25000.0,
        option_type: "CE"
      )
    end

    let!(:entry) do
      OptionChainEntry.create!(
        option_chain: chain,
        option_contract: nifty_ce,
        ltp: 120.50,
        oi: 5000,
        volume: 15000,
        iv: 14.50,
        delta: 0.55,
        gamma: 0.002,
        theta: -5.50,
        vega: 0.12
      )
    end

    it "persists option chain entries and snapshot metrics" do
      expect(chain.option_chain_entries).to include(entry)
      expect(entry.option_contract).to eq(nifty_ce)
      expect(entry.ltp).to eq(120.50)
      expect(entry.delta).to eq(0.55)
    end
  end

  describe "Candles and Watchlists" do
    it "persists watchlists and tracks uniqueness" do
      wl = Watchlist.create!(name: "High Priority Indices")
      WatchlistItem.create!(watchlist: wl, instrument: reliance)

      expect(wl.instruments).to include(reliance)
      expect {
        WatchlistItem.create!(watchlist: wl, instrument: reliance)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "persists candles and prevents duplicates" do
      Candle.create!(
        security_id: 3045,
        timeframe: "1m",
        candle_time: Time.zone.parse("2026-06-20 09:15:00"),
        open: 2500.00,
        high: 2505.00,
        low: 2498.00,
        close: 2502.50,
        volume: 1500
      )

      expect {
        Candle.create!(
          security_id: 3045,
          timeframe: "1m",
          candle_time: Time.zone.parse("2026-06-20 09:15:00"),
          open: 2501.00,
          high: 2504.00,
          low: 2499.00,
          close: 2503.00,
          volume: 2000
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
