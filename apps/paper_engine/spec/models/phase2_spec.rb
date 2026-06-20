require 'rails_helper'

RSpec.describe "Phase 2 Architecture", type: :model do
  it "completes phase 2 tests" do
    runtime = Runtime.create!(name: "Test", mode: "paper", active: true)
    account = Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR")
    
    # Buy 100 @ 1000
    order1 = Orders::Order.create!(runtime: runtime, account: account, symbol: "RELIANCE", side: "BUY", quantity: 100, price: 1000, status: "pending")
    trade1 = Execution::TradeProcessor.process(order1)
    
    expect(trade1.trade_value).to eq(100_000)
    
    # Ledger Balanced?
    debits = Accounting::LedgerEntry.where(reference_type: "Trade", reference_id: trade1.id).sum(:debit)
    credits = Accounting::LedgerEntry.where(reference_type: "Trade", reference_id: trade1.id).sum(:credit)
    expect(debits).to eq(credits)
    expect(debits).to eq(100_000)
    
    # Position
    pos = Projections::Position.find_by(runtime: runtime, symbol: "RELIANCE")
    expect(pos.quantity).to eq(100)
    expect(pos.average_price).to eq(1000)

    # Scale in
    order2 = Orders::Order.create!(runtime: runtime, account: account, symbol: "RELIANCE", side: "BUY", quantity: 50, price: 1200, status: "pending")
    trade2 = Execution::TradeProcessor.process(order2)
    pos.reload
    expect(pos.quantity).to eq(150)
    expect(pos.average_price.to_f).to be_within(0.1).of(1066.67)

    # Scale out
    order3 = Orders::Order.create!(runtime: runtime, account: account, symbol: "RELIANCE", side: "SELL", quantity: 25, price: 1300, status: "pending")
    trade3 = Execution::TradeProcessor.process(order3)
    pos.reload
    expect(pos.quantity).to eq(125)
    expect(pos.average_price.to_f).to be_within(0.1).of(1066.67)

    # Funds
    fund = Projections::Fund.find_by(runtime: runtime)
    # Buy 100k, Buy 60k, Sell 32.5k => Net cash: -127500
    expect(fund.cash_balance).to eq(-127500)

    # Replay
    expect(Runtime::ReplayRuntime.call(runtime)).to be_truthy
    pos.reload
    expect(pos.quantity).to eq(125)
  end
end
