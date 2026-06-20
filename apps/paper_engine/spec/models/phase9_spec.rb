require 'rails_helper'

RSpec.describe "Phase 9 Strategy Runtime & Orchestration", type: :model do
  let!(:runtime) { Runtime.create!(name: "Autonomy Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Autonomy Account", currency: "INR") }
  
  let!(:strategy) do
    StrategyRuntime::Strategy.create!(
      runtime_id: runtime.id,
      name: "Core ETF Accumulator",
      strategy_type: "ETF_ACCUMULATION",
      code: "ETF_001",
      status: "DRAFT"
    )
  end

  let!(:mandate) do
    StrategyRuntime::InvestmentMandate.create!(
      strategy: strategy,
      name: "Retirement Core",
      target_return: 0.12,
      risk_budget: 0.05,
      allowed_segments: ["NIFTYBEES", "BANKBEES", "LIQUIDBEES"]
    )
  end

  let!(:allocation) do
    Portfolio::PortfolioAllocation.create!(
      runtime: runtime,
      name: "Core Allocation",
      target_weights: { "NIFTYBEES" => 0.60, "BANKBEES" => 0.30, "LIQUIDBEES" => 0.10 },
      cash_allocation: 1_000_000
    )
  end

  it "Strategy Registry and Mandate Engine load correctly" do
    expect(strategy.name).to eq("Core ETF Accumulator")
    expect(mandate.allowed_segments).to include("NIFTYBEES")
  end

  it "Signal Engine rejects signals outside allowed mandate segments" do
    signal = StrategyRuntime::Signal.create!(
      strategy: strategy,
      investment_mandate: mandate,
      symbol: "RELIANCE",
      action: "BUY",
      confidence: 0.9
    )

    result = StrategyRuntime::SignalEngine.process(signal)
    
    expect(result[:success]).to be_falsey
    expect(result[:reason]).to eq("SYMBOL_NOT_IN_MANDATE")
    expect(signal.reload.status).to eq("REJECTED")
  end

  it "Signal Engine validates signals inside allowed mandate segments" do
    signal = StrategyRuntime::Signal.create!(
      strategy: strategy,
      investment_mandate: mandate,
      symbol: "NIFTYBEES",
      action: "BUY",
      confidence: 0.95
    )

    result = StrategyRuntime::SignalEngine.process(signal)
    
    expect(result[:success]).to be_truthy
    expect(signal.reload.status).to eq("VALIDATED")

    # Check validation event
    event = Events::DomainEvent.last
    expect(event.event_type).to eq('signal.validated')
  end

  it "Promotion Pipeline moves strategy from DRAFT to LIVE_ENABLED" do
    expect(strategy.status).to eq("DRAFT")
    
    result = StrategyRuntime::PromotionPipeline.promote(strategy)
    
    expect(result[:success]).to be_truthy
    expect(strategy.reload.status).to eq("LIVE_ENABLED")
    
    event = Events::DomainEvent.last
    expect(event.event_type).to eq('strategy.promoted')
  end

  it "Portfolio Rebalancer executes and generates an event" do
    result = Portfolio::Rebalancer.rebalance(allocation, runtime, account)
    
    expect(result[:success]).to be_truthy
    event = Events::DomainEvent.last
    expect(event.event_type).to eq('rebalance.executed')
  end
end
