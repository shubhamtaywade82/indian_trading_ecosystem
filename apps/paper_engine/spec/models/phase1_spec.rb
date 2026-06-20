require 'rails_helper'

RSpec.describe "Phase 1: Write-Side Core Loop", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }
  let(:reliance) { "RELIANCE" }

  it "buys, posts the ledger, derives position accurately" do
    trade = TradeProcessor.execute(account: account, instrument: reliance, side: 'buy', qty: 100, price: 1000)

    expect(LedgerEntry.balance_for(account, "cash").to_i).to eq(-100_000)
    expect(LedgerEntry.balance_for(account, "inventory:RELIANCE").to_i).to eq(100_000)

    pos = PositionCalculator.for(account, reliance)
    expect(pos[:qty]).to eq(100)
    expect(pos[:avg_price].to_f).to eq(1000.0)

    sell_trade = TradeProcessor.execute(account: account, instrument: reliance, side: 'sell', qty: 40, price: 1200)

    expect(LedgerEntry.balance_for(account, "cash").to_i).to eq(-52_000) 
    expect(LedgerEntry.balance_for(account, "inventory:RELIANCE").to_i).to eq(60_000) 
    expect(LedgerEntry.balance_for(account, "realized_pnl").to_i).to eq(-8_000)

    pos2 = PositionCalculator.for(account, reliance)
    expect(pos2[:qty].to_i).to eq(60)
    expect(pos2[:avg_price].to_f).to eq(1000.0) 
  end
end
