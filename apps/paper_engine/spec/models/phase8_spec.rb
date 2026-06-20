require 'rails_helper'

RSpec.describe "Phase 8 Broker Emulation Layer", type: :model do
  let!(:runtime) { Runtime.create!(name: "Broker Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Broker Account", currency: "INR") }
  
  let!(:kite_profile) do
    BrokerProfiles::BrokerProfile.create!(
      name: "Kite V3", broker_type: "KITE", version: "3.0",
      rules: { "supported_products" => ["CNC", "MIS"], "freeze_qty" => 1800, "margin_multiplier_mis" => 5.0 }
    )
  end

  before do
    Broker::MarginAccount.create!(runtime: runtime, account: account, cash_balance: 1_000_000, available_margin: 1_000_000)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'CNC', cash_requirement_pct: 1.0)
    Exchange::OrderBook.clear_all
    allow(Market::SessionEngine).to receive(:evaluate).and_return({ success: true })
  end

  it "validates supported products via Product Emulator" do
    runtime.update!(broker_profile: kite_profile)
    
    result = Execution::ExecutionGateway.place_order(
      runtime, account, 
      { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "NRML" }
    )
    
    expect(result[:success]).to be_falsey
    expect(result[:errors][:broker]).to include("PRODUCT_NOT_SUPPORTED_BY_BROKER")
  end

  it "splits orders based on freeze quantity rules" do
    runtime.update!(broker_profile: kite_profile)
    
    result = Execution::ExecutionGateway.place_order(
      runtime, account, 
      { symbol: "NIFTY", side: "BUY", quantity: 5000, price: 100, order_type: "MARKET", product_type: "MIS" }
    )
    
    expect(result[:success]).to be_truthy
    
    # 5000 split by 1800: 1800, 1800, 1400. Total 3 orders created.
    expect(Orders::Order.count).to eq(3)
    quantities = Orders::Order.pluck(:quantity).sort
    expect(quantities).to eq([1400, 1800, 1800])
    
    expect(Events::DomainEvent.where(event_type: 'order.freeze_split').count).to eq(1)
  end

  it "emulates broker-specific MIS margin multipliers" do
    runtime.update!(broker_profile: kite_profile)
    
    # Base margin for 10 qty at 1000 is 10000. For MIS, base calculator says 0.2 -> 2000.
    # Kite profile mis multiplier = 5.0, so final margin = 2000 / 5.0 = 400.
    
    result = Execution::ExecutionGateway.place_order(
      runtime, account, 
      { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "MIS" }
    )
    
    expect(result[:success]).to be_truthy
    margin_account = Broker::MarginAccount.last
    expect(margin_account.blocked_margin).to eq(400)
  end

  it "routes live orders to ApiAdapters instead of OMS" do
    runtime.update!(broker_profile: kite_profile, mode: 'live')
    
    result = Execution::ExecutionGateway.place_order(
      runtime, account, 
      { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )
    
    expect(result[:success]).to be_truthy
    expect(result[:broker_order_id]).to match(/^KITE_/)
    expect(Orders::Order.count).to eq(0) # Did not go through Paper OMS
  end
end
