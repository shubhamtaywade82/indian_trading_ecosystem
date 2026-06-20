require 'rails_helper'

RSpec.describe "Phase 6 Portfolio Lifecycle", type: :model do
  let!(:runtime) { Runtime.create!(name: "Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR") }
  
  before do
    Broker::MarginAccount.create!(runtime: runtime, account: account, cash_balance: 100_000, available_margin: 100_000)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'CNC', cash_requirement_pct: 1.0)
    
    Accounting::ChargeProfile.create!(
      broker: 'Generic', segment: 'equity', product_type: 'CNC',
      stt_pct: 0.001, gst_pct: 0.18, exchange_pct: 0.00003, sebi_pct: 0.000001, stamp_pct: 0.00015,
      brokerage_flat: 0, brokerage_pct: 0.001
    )
    
    Exchange::OrderBook.clear_all
  end

  it "calculates and posts charges on trade execution" do
    # Tick arrives
    Exchange::TickProcessor.process(
      runtime_id: runtime.id,
      symbol: "RELIANCE",
      tick: { ltp: 1000, bid: 999, bid_qty: 1000, ask: 1000, ask_qty: 800 }
    )

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC" }
    )

    expect(result[:success]).to be_truthy
    trade = Trades::Trade.last
    expect(trade).to be_present

    charges = Accounting::ChargesEngine.calculate(trade)
    expect(charges[:total]).to be > 0

    cashflows = Accounting::PortfolioCashflow.where(cashflow_type: 'CHARGES')
    expect(cashflows.count).to eq(1)
    expect(cashflows.first.amount).to eq(-charges[:total])

    margin = Broker::MarginAccount.find_by(runtime: runtime, account: account)
    expect(margin.cash_balance).to eq(100_000 - charges[:total])
  end

  it "creates pending settlement lot for CNC trades and processes them" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "MARKET", product_type: "CNC" }
    )

    trade = Trades::Trade.last

    lot = Accounting::SettlementLot.last
    expect(lot).to be_present
    expect(lot.status).to eq('PENDING')
    expect(lot.symbol).to eq("RELIANCE")

    # Fast forward to settlement date
    Accounting::SettlementEngine.process_settlements(Date.today + 2.days)

    expect(lot.reload.status).to eq('SETTLED')
    expect(Events::DomainEvent.where(event_type: 'trade.settled').count).to eq(1)
  end

  it "applies dividend corporate actions to settled holdings" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "TCS", side: "BUY", quantity: 100, price: 1000, order_type: "MARKET", product_type: "CNC" }
    )
    trade = Trades::Trade.last

    Accounting::SettlementLot.last.update!(settlement_date: Date.yesterday, status: 'SETTLED')

    action = Accounting::CorporateAction.create!(
      runtime_id: runtime.id, symbol: "TCS", action_type: 'DIVIDEND', ex_date: Date.today, details: { 'amount' => 20.0 }
    )

    Accounting::CorporateActionEngine.apply(action)

    expect(action.reload.status).to eq('APPLIED')
    cashflow = Accounting::PortfolioCashflow.find_by(cashflow_type: 'DIVIDEND')
    expect(cashflow.amount).to eq(2000.0) # 100 shares * 20
  end

  it "applies split corporate actions to settled holdings" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "INFY", side: "BUY", quantity: 100, price: 1000, order_type: "MARKET", product_type: "CNC" }
    )
    trade = Trades::Trade.last
    lot = Accounting::SettlementLot.last
    lot.update!(settlement_date: Date.yesterday, status: 'SETTLED')

    action = Accounting::CorporateAction.create!(
      runtime_id: runtime.id, symbol: "INFY", action_type: 'SPLIT', ex_date: Date.today, details: { 'ratio' => '1:5' }
    )

    Accounting::CorporateActionEngine.apply(action)

    expect(lot.reload.quantity).to eq(500)
    expect(Events::DomainEvent.where(event_type: 'split.applied').count).to eq(1)
  end

  it "calculates correct tax" do
    order1 = Orders::Order.create!(runtime: runtime, account: account, symbol: "ITC", side: "BUY", quantity: 100, price: 200, status: 'filled', segment: 'equity')
    buy = Trades::Trade.create!(
      runtime_id: runtime.id, order_id: order1.id, symbol: "ITC", side: "BUY", quantity: 100, price: 200, trade_value: 20000, executed_at: 2.years.ago, created_at: 2.years.ago
    )
    order2 = Orders::Order.create!(runtime: runtime, account: account, symbol: "ITC", side: "SELL", quantity: 100, price: 300, status: 'filled', segment: 'equity')
    sell = Trades::Trade.create!(
      runtime_id: runtime.id, order_id: order2.id, symbol: "ITC", side: "SELL", quantity: 100, price: 300, trade_value: 30000, executed_at: Time.current, created_at: Time.current
    )

    tax = Accounting::TaxEngine.calculate_tax(buy, sell)
    expect(tax[:type]).to eq('LTCG')
    expect(tax[:pnl]).to eq(10000)
    expect(tax[:estimated_tax]).to eq(1000) # 10%
  end
end
