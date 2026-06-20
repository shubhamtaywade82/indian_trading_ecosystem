require 'rails_helper'

RSpec.describe "Phase 7: Market Realism (Slippage, Latency, Replay)", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }

  before do
    JournalEntry.transaction do
      j = JournalEntry.create!(account: account, reference_type: 'deposit', reference_id: 1, description: 'Initial Deposit')
      j.ledger_entries.create!(account: account, ledger_account: 'cash', debit: 1_000_000)
      j.ledger_entries.create!(account: account, ledger_account: 'equity', credit: 1_000_000)
    end
    
    MarginAccount.create!(
      account_id: account.id,
      cash_balance: 1_000_000,
      blocked_margin: 0,
      available_margin: 1_000_000,
      mtm_pnl: 0,
      realized_pnl: 0
    )
    
    ChargeProfile.create!(
      broker: 'paper-generic', product_type: 'CNC',
      stt_pct: 0.001, gst_pct: 0.18, exchange_pct: 0.0000325, sebi_pct: 0.000001, stamp_pct: 0.00015, brokerage_flat: 20.0
    )
  end

  it "simulates slippage on MARKET orders" do
    ENV['SIMULATE_SLIPPAGE'] = 'true'
    begin
      order = PlaceOrder.call(account: account, payload: {
        instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, price: 2500
      })
      
      # 5 bps slippage on 2500 is 1.25, so buy price should be 2501.25
      MatchingEngine.process_tick({ instrument_id: 'RELIANCE', ltp: 2500, volume: 100, time: Time.current })
      
      trade = PaperTrade.find_by(paper_order_id: order.id)
      expect(trade).not_to be_nil
      expect(trade.fill_price.to_f).to eq(2501.25)
    ensure
      ENV.delete('SIMULATE_SLIPPAGE')
    end
  end

  it "does not apply slippage on LIMIT orders" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'INFY', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 100, price: 1500
    })
    
    MatchingEngine.process_tick({ instrument_id: 'INFY', ltp: 1500, volume: 100, time: Time.current })
    
    trade = PaperTrade.find_by(paper_order_id: order.id)
    expect(trade).not_to be_nil
    expect(trade.fill_price.to_f).to eq(1500.0)
  end

  it "runs historical replay correctly" do
    # Schedule two ticks at different times
    base_time = Time.parse("2026-06-20 09:15:00")
    ticks = [
      { instrument_id: 'HDFCBANK', ltp: 1600, volume: 500, time: base_time },
      { instrument_id: 'HDFCBANK', ltp: 1590, volume: 200, time: base_time + 1.minute }
    ]
    
    # Place a limit order at 1595
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'HDFCBANK', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 100, price: 1595
    })
    
    replay = Paper::Replay::HistoricalReplayEngine.new(ticks, speed_multiplier: 0) # run instantly
    replay.run!
    
    trade = PaperTrade.find_by(paper_order_id: order.id)
    expect(trade).not_to be_nil
    expect(trade.fill_price.to_f).to eq(1590.0) # filled at the second tick
  end

  it "simulates latency when configured" do
    ENV['SIMULATE_LATENCY'] = 'true'
    
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'TCS', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 10, price: 3000
    })
    
    start_time = Time.current
    MatchingEngine.process_tick({ instrument_id: 'TCS', ltp: 3000, volume: 10, time: Time.current })
    elapsed = Time.current - start_time
    
    expect(elapsed).to be > 0.02 # At least 20ms of latency due to base 50ms + jitter
    
    trade = PaperTrade.find_by(paper_order_id: order.id)
    expect(trade).not_to be_nil
  end
end
