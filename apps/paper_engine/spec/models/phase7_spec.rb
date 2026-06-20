require 'rails_helper'

RSpec.describe "Phase 7 Market Realism & Historical Replay", type: :model do
  let!(:runtime) { Runtime.create!(name: "Test Replay", mode: "replay", active: true, slippage_model: 'FIXED_BPS', latency_model: 'FIXED') }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Replay Account", currency: "INR") }
  
  before do
    Broker::MarginAccount.create!(runtime: runtime, account: account, cash_balance: 10_000_000, available_margin: 10_000_000)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'CNC', cash_requirement_pct: 1.0)
    Exchange::OrderBook.clear_all
  end

  it "simulates an out-of-hours market rejection" do
    # Replay session mock 09:00 AM (Pre-market)
    session = Replay::HistoricalReplayEngine.start(runtime.id, Time.zone.parse("2026-06-20 09:00:00"), Time.zone.parse("2026-06-20 15:30:00"), 'TICK')
    
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "HDFCBANK", side: "BUY", quantity: 10, price: 1000, order_type: "MARKET", product_type: "CNC" }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:market]).to include('MARKET_CLOSED')
  end

  it "simulates fixed slippage during active replay session" do
    # Advance clock to 10:00 AM (Market Open)
    session = Replay::HistoricalReplayEngine.start(runtime.id, Time.zone.parse("2026-06-20 09:00:00"), Time.zone.parse("2026-06-20 15:30:00"), 'TICK')
    Replay::HistoricalReplayEngine.advance_tick(
      session.id,
      { symbol: "HDFCBANK", ltp: 1000, bid: 999, bid_qty: 1000, ask: 1000, ask_qty: 800 },
      Time.zone.parse("2026-06-20 10:00:00")
    )

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "HDFCBANK", side: "BUY", quantity: 10, price: 1000, order_type: "MARKET", product_type: "CNC" }
    )

    expect(result[:success]).to be_truthy
    trade = Trades::Trade.last
    expect(trade).to be_present

    # Slippage applied (Fixed BPS 0.0005) -> 1000 * 0.0005 = 0.5. BUY gets higher fill price.
    expect(trade.price).to eq(1000.5)
  end

  it "simulates latency via latency simulator" do
    latency = Execution::LatencySimulator.simulate(runtime)
    expect(latency).to eq(0.05) # 50ms fixed
  end
end
