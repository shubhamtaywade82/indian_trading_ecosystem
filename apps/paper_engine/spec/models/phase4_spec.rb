require 'rails_helper'

RSpec.describe "Phase 4: Margin Engine & RMS", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }

  before do
    # Fund the account with 100,000 cash via ledger
    JournalEntry.transaction do
      j = JournalEntry.create!(account: account, reference_type: 'deposit', reference_id: 1, description: 'Initial Deposit')
      j.ledger_entries.create!(account: account, ledger_account: 'cash', debit: 100_000)
      j.ledger_entries.create!(account: account, ledger_account: 'equity', credit: 100_000)
    end
  end

  it "rejects order if insufficient funds" do
    # Trying to buy 150k worth of stock on CNC (100% margin) with only 100k
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 100, price: 1500
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('INSUFFICIENT_FUNDS')
  end

  it "accepts order if sufficient funds and blocks margin" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 10, price: 1500
    })

    expect(order.status).to eq('OPEN')
    ma = MarginAccount.find_by(account_id: account.id)
    expect(ma.blocked_margin).to eq(15_000)
    expect(ma.available_margin).to eq(85_000)
  end

  it "releases margin on order cancellation" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 10, price: 1500
    })

    ma = MarginAccount.find_by(account_id: account.id)
    expect(ma.blocked_margin).to eq(15_000)

    CancelOrder.call(order: order)

    ma.reload
    expect(ma.blocked_margin).to eq(0)
    expect(ma.available_margin).to eq(100_000)
  end

  it "rejects short selling in CNC without holdings" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'sell', order_type: 'LIMIT', product_type: 'CNC', qty: 10, price: 1500
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('Short selling not allowed')
  end
  
  it "requires only 20% margin for MIS" do
    # 100 * 1500 = 150k. In MIS (20%), requires 30k. We have 100k, so it should succeed.
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'MIS', qty: 100, price: 1500
    })

    expect(order.status).to eq('OPEN')
    ma = MarginAccount.find_by(account_id: account.id)
    expect(ma.blocked_margin).to eq(30_000)
    expect(ma.available_margin).to eq(70_000)
  end
end
