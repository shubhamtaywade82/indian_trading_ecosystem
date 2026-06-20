require 'rails_helper'

RSpec.describe "Phase 3: Matching Engine", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }

  before do
    ENV.delete('BROKER_PROFILE')
    MarginAccount.find_or_create_by!(account_id: account.id) do |ma|
      ma.cash_balance      = 10_000_000
      ma.blocked_margin    = 0
      ma.available_margin  = 10_000_000
      ma.mtm_pnl           = 0
      ma.realized_pnl      = 0
    end
  end

  it "matches Market orders immediately" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100
    })

    MatchingEngine.process_tick({ instrument_id: 'RELIANCE', ltp: 2500, volume: 500 })

    order.reload
    expect(order.status).to eq('FILLED')
    expect(order.filled_qty).to eq(100)
    expect(order.paper_trades.first.fill_price).to eq(2500)
  end

  it "matches Limit Buy orders when LTP <= Limit Price" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'HDFC', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 50, price: 1500
    })

    # Tick above limit, should not fill
    MatchingEngine.process_tick({ instrument_id: 'HDFC', ltp: 1510, volume: 500 })
    expect(order.reload.status).to eq('OPEN')

    # Tick at limit, should fill
    MatchingEngine.process_tick({ instrument_id: 'HDFC', ltp: 1500, volume: 500 })
    expect(order.reload.status).to eq('FILLED')
  end

  it "handles partial fills based on tick volume" do
    # Seed holdings so the sell side passes RMS
    TradeProcessor.execute(account: account, instrument: 'INFY', side: 'buy', qty: 200, price: 1400)
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'INFY', side: 'sell', order_type: 'LIMIT', product_type: 'CNC', qty: 200, price: 1400
    })

    # Partial tick
    MatchingEngine.process_tick({ instrument_id: 'INFY', ltp: 1405, volume: 150 })
    
    order.reload
    expect(order.status).to eq('PARTIALLY_FILLED')
    expect(order.filled_qty).to eq(150)
    expect(order.remaining_qty).to eq(50)

    # Remaining tick
    MatchingEngine.process_tick({ instrument_id: 'INFY', ltp: 1410, volume: 100 })
    
    order.reload
    expect(order.status).to eq('FILLED')
    expect(order.filled_qty).to eq(200)
  end

  it "triggers SL orders when trigger price is hit" do
    # Seed holdings so the sell-side SL-M passes RMS
    TradeProcessor.execute(account: account, instrument: 'TCS', side: 'buy', qty: 100, price: 3100)
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'TCS', side: 'sell', order_type: 'SL-M', product_type: 'CNC', qty: 100, trigger_price: 3000
    })

    # Sell SL is triggered when LTP drops to or below trigger price
    MatchingEngine.process_tick({ instrument_id: 'TCS', ltp: 3010, volume: 500 })
    expect(order.reload.status).to eq('OPEN')
    expect(order.order_type).to eq('SL-M')

    MatchingEngine.process_tick({ instrument_id: 'TCS', ltp: 2995, volume: 500 })
    order.reload
    expect(order.status).to eq('FILLED')
    expect(order.order_status_transitions.pluck(:reason)).to include(a_string_matching(/Stop Loss triggered/))
  end
end
