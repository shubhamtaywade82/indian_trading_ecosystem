require 'rails_helper'

RSpec.describe "Phase 5 Risk Engine", type: :model do
  let!(:runtime) { Runtime.create!(name: "Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR") }
  let!(:strategy) { Risk::Strategy.create!(runtime: runtime, name: "Breakout", code: "BRK") }

  before do
    Broker::MarginAccount.create!(runtime: runtime, account: account, cash_balance: 100_000, available_margin: 100_000)
    Broker::MarginRequirement.create!(segment: 'equity', product_type: 'CNC', cash_requirement_pct: 1.0)
    
    Risk::RiskProfile.create!(
      runtime: runtime, strategy: strategy,
      max_daily_loss: 5000,
      max_drawdown_pct: 0.1,
      max_position_size: 50000
    )
    
    Risk::RiskSnapshot.create!(
      runtime: runtime, strategy: strategy, snapshot_date: Date.today,
      equity: 100_000, peak_equity: 100_000, daily_pnl: 0
    )
  end

  it "accepts order if no risk limits breached" do
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC", strategy_id: strategy.id }
    )

    expect(result[:success]).to be_truthy
  end

  it "rejects order if position size limit is breached" do
    # max_position_size is 50,000. 100 * 1000 = 100,000
    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 100, price: 1000, order_type: "LIMIT", product_type: "CNC", strategy_id: strategy.id }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:risk]).to include("POSITION_LIMIT_BREACH")
  end

  it "triggers daily loss kill switch and rejects order" do
    snapshot = Risk::RiskSnapshot.last
    snapshot.update!(daily_pnl: -6000) # Exceeds max_daily_loss of 5000

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC", strategy_id: strategy.id }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:risk]).to include("DAILY_LOSS_BREACH")
    
    expect(strategy.reload.status).to eq('STOPPED')
    expect(Events::DomainEvent.where(event_type: 'risk.kill_switch_activated').count).to eq(1)
  end

  it "triggers drawdown kill switch and rejects order" do
    snapshot = Risk::RiskSnapshot.last
    # Peak is 100,000. Current equity 85,000. Drawdown is 15%. Max allowed is 10% (0.1).
    snapshot.update!(equity: 85_000)

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC", strategy_id: strategy.id }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:risk]).to include("DRAWDOWN_BREACH")
    
    expect(strategy.reload.status).to eq('STOPPED')
  end

  it "blocks orders for a stopped strategy immediately" do
    strategy.update!(status: 'STOPPED')

    result = OMS::CreateOrder.call(
      runtime: runtime, account: account,
      params: { symbol: "RELIANCE", side: "BUY", quantity: 10, price: 1000, order_type: "LIMIT", product_type: "CNC", strategy_id: strategy.id }
    )

    expect(result[:success]).to be_falsey
    expect(result[:errors][:risk]).to include("STRATEGY_STOPPED")
  end
end
