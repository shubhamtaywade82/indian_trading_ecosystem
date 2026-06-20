require 'rails_helper'

RSpec.describe "Phase 8: Broker Virtualization", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Dhan Paper Account") }

  before do
    JournalEntry.transaction do
      j = JournalEntry.create!(account: account, reference_type: 'deposit', reference_id: 1, description: 'Initial Deposit')
      j.ledger_entries.create!(account: account, ledger_account: 'cash', debit: 1_000_000)
      j.ledger_entries.create!(account: account, ledger_account: 'equity', credit: 1_000_000)
    end
    
    MarginAccount.create!(
      account_id: account.id, cash_balance: 1_000_000, blocked_margin: 0, available_margin: 1_000_000, mtm_pnl: 0, realized_pnl: 0
    )
    
    BrokerProfile.create!(
      broker_name: 'dhan',
      supports_amo: true,
      max_order_qty: 5000,
      block_penny_stocks: true,
      restrict_illiquid_options: true,
      error_format: 'dhan'
    )
    
    BrokerProfile.create!(
      broker_name: 'kite',
      supports_amo: true,
      max_order_qty: 10000,
      block_penny_stocks: false,
      restrict_illiquid_options: true,
      error_format: 'kite'
    )
  end

  it "enforces broker specific max order quantity" do
    ENV['BROKER_PROFILE'] = 'dhan'
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 6000, price: 2500
    })
    
    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('RS-MAX_QTY_EXCEEDED')
    expect(order.order_status_transitions.last.reason).to include('Maximum order quantity is 5000')
  end

  it "enforces broker specific instrument rules with broker specific error formatting" do
    ENV['BROKER_PROFILE'] = 'dhan'
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'SUZLON_PENNY', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, price: 50
    })
    
    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('RS-INSTRUMENT_RESTRICTED')
    expect(order.order_status_transitions.last.reason).to include('Penny stocks are blocked')
  end

  it "allows Kite mode to bypass penny stock block with Kite formatting" do
    ENV['BROKER_PROFILE'] = 'kite'
    
    # Passes broker rule, might fail RMS if no cash but here it has 1M cash, 100*50 = 5k. Will pass!
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'SUZLON_PENNY', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, price: 50
    })
    
    expect(order.status).to eq('OPEN')
    
    # However illiquid options are blocked in Kite
    order_illiquid = PlaceOrder.call(account: account, payload: {
      instrument_id: 'NIFTY_FAR_OTM', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 50, price: 10
    })
    
    expect(order_illiquid.status).to eq('REJECTED')
    expect(order_illiquid.order_status_transitions.last.reason).to include('InputException')
    expect(order_illiquid.order_status_transitions.last.reason).to include('Trading in illiquid options is restricted')
  end
end
