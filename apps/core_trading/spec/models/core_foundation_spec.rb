require 'rails_helper'

RSpec.describe "Core Trading System - Foundation & Market Data", type: :model do
  let!(:instrument) do
    Core::Instrument.create!(
      symbol: "RELIANCE",
      exchange: "NSE",
      segment: "NSE_EQ",
      instrument_type: "EQ",
      name: "Reliance Industries Limited",
      lot_size: 1,
      tick_size: 0.05
    )
  end

  let!(:alias_record) do
    Core::InstrumentAlias.create!(
      instrument: instrument,
      alias_name: "RELIANCE-EQ",
      provider: "dhan"
    )
  end

  it "InstrumentMaster finds instrument by symbol" do
    found = Core::InstrumentMaster.find_by_symbol("RELIANCE", exchange: "NSE")
    expect(found).to eq(instrument)
  end

  it "InstrumentMaster finds instrument by alias" do
    found = Core::InstrumentMaster.find_by_alias("RELIANCE-EQ", provider: "dhan")
    expect(found).to eq(instrument)
  end

  it "MarketData::Hub routes requests to correct adapter" do
    # Dhan Adapter mock behavior
    dhan_snapshot = MarketData::Hub.fetch_snapshot("RELIANCE", source: "dhan")
    expect(dhan_snapshot[:symbol]).to eq("RELIANCE")
    expect(dhan_snapshot[:last_price]).to be > 0

    # Replay Adapter behavior
    Core::MarketDataSnapshot.create!(
      instrument: instrument,
      last_price: 2500.50,
      volume: 100000,
      timestamp: Time.current
    )

    replay_snapshot = MarketData::Hub.fetch_snapshot("RELIANCE", source: "replay")
    expect(replay_snapshot[:last_price]).to eq(2500.50)
  end
end
