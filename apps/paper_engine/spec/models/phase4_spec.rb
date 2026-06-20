require 'rails_helper'

RSpec.describe "Phase 4 Margin Engine & RMS", type: :model do
  let!(:runtime) { Runtime.create!(name: "Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR") }
  
  before do
    Broker::MarginAccount.create!(runtime: runtime, account: account, cash_balance: 100_000, available_margin: 100_000)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'MIS', cash_requirement_pct: 0.2)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'CNC', cash_requirement_pct: 1.0)
  end

  it "accepts order and blocks margin if funds are sufficient" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )

    expect(result[:success]).to be_truthy
    
    margin = Broker::MarginAccount.last
    expect(margin.blocked_margin).to eq(100_000)
    expect(margin.available_margin).to eq(0)
    
    expect(Events::DomainEvent.where(event_type: 'margin.blocked').count).to eq(1)
  end

  it "rejects order if insufficient funds" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 200, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:rms]).to include("INSUFFICIENT_FUNDS")
    
    margin = Broker::MarginAccount.last
    expect(margin.blocked_margin).to eq(0)
    expect(margin.available_margin).to eq(100_000)
    
    expect(Events::DomainEvent.where(event_type: 'order.rejected').count).to eq(1)
  end

  it "calculates correct margin for MIS orders" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 200, price: 1000, order_type: "LIMIT", product_type: "MIS" }
    )

    expect(result[:success]).to be_truthy
    
    margin = Broker::MarginAccount.last
    # 200 * 1000 = 200,000. 20% of 200,000 = 40,000
    expect(margin.blocked_margin).to eq(40_000)
    expect(margin.available_margin).to eq(60_000)
  end

  it "releases margin when order is cancelled" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 50, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )

    order = result[:order]
    expect(Broker::MarginAccount.last.available_margin).to eq(50_000)

    cancel_result = OMS::CancelOrder.call(order)
    expect(cancel_result[:success]).to be_truthy

    expect(Broker::MarginAccount.last.available_margin).to eq(100_000)
    expect(Broker::MarginAccount.last.blocked_margin).to eq(0)
    expect(Events::DomainEvent.where(event_type: 'margin.released').count).to eq(1)
  end

  it "releases only unused margin upon partial fill cancel" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )
    order = result[:order]
    
    order.update!(filled_quantity: 40, status: 'partially_filled')
    
    OMS::CancelOrder.call(order)

    # Initially 100_000 blocked. Filled 40 (40_000). Remaining 60 should be released.
    margin = Broker::MarginAccount.last
    expect(margin.blocked_margin).to eq(40_000) # Remaining 40k blocked for the executed trade
    expect(margin.available_margin).to eq(60_000)
  end
end
