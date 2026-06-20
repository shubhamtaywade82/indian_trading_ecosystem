require 'rails_helper'

RSpec.describe "Phase 3 Matching Engine", type: :model do
  let!(:runtime) { Runtime.create!(name: "Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR") }

  before do
    Exchange::OrderBook.clear_all
  end

  it "matches market orders filling against asks and creates trades" do
    # Tick arrives
    Exchange::TickProcessor.process(
      runtime_id: runtime.id,
      symbol: "RELIANCE",
      tick: { ltp: 2500, bid: 2499, bid_qty: 1000, ask: 2501, ask_qty: 800 }
    )

    # Place order
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 150, order_type: "MARKET" }
    )
    expect(result[:success]).to be_truthy
    order = result[:order]
    
    order.reload
    expect(order.status).to eq('filled')
    expect(order.filled_quantity).to eq(150)
    expect(order.average_price).to eq(2501)
    
    expect(Trades::Trade.count).to eq(1)
    expect(Trades::Trade.last.quantity).to eq(150)
    expect(Trades::Trade.last.price).to eq(2501)
  end

  it "partially fills limit orders and queues the remainder" do
    Exchange::TickProcessor.process(
      runtime_id: runtime.id,
      symbol: "RELIANCE",
      tick: { ltp: 2500, bid: 2499, bid_qty: 100, ask: 2500, ask_qty: 50 }
    )

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, order_type: "LIMIT", price: 2500 }
    )
    order = result[:order]
    order.reload

    expect(order.status).to eq('partially_filled')
    expect(order.filled_quantity).to eq(50)
    
    queue_entry = Execution::QueueEntry.last
    expect(queue_entry.order_id).to eq(order.id)
    expect(queue_entry.remaining_quantity).to eq(50)

    # Next tick arrives that can fill the rest
    Exchange::TickProcessor.process(
      runtime_id: runtime.id,
      symbol: "RELIANCE",
      tick: { ltp: 2500, bid: 2499, bid_qty: 100, ask: 2500, ask_qty: 100 }
    )

    order.reload
    expect(order.status).to eq('filled')
    expect(order.filled_quantity).to eq(100)
    expect(Execution::QueueEntry.count).to eq(0)
  end

  it "enforces time priority for limit orders" do
    result1 = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, order_type: "LIMIT", price: 2500 }
    )
    result2 = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, order_type: "LIMIT", price: 2500 }
    )

    expect(Execution::QueueEntry.count).to eq(2)
    q1 = Execution::QueueEntry.first
    q2 = Execution::QueueEntry.last
    expect(q1.queue_position).to be < q2.queue_position

    # Tick provides 150 ask_qty at 2500
    Exchange::TickProcessor.process(
      runtime_id: runtime.id,
      symbol: "RELIANCE",
      tick: { ltp: 2500, bid: 2499, bid_qty: 100, ask: 2500, ask_qty: 150 }
    )

    o1 = result1[:order].reload
    o2 = result2[:order].reload

    expect(o1.status).to eq('filled')
    expect(o2.status).to eq('partially_filled')
    expect(o2.filled_quantity).to eq(50)
  end
end
