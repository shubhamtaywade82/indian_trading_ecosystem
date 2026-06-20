require 'rails_helper'

RSpec.describe "Phase 2: OMS State Machine", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }

  before do
    ENV.delete('BROKER_PROFILE')
    MarginAccount.find_or_create_by!(account_id: account.id) do |ma|
      ma.cash_balance      = 10_000_000
      ma.blocked_margin    = 0
      ma.available_margin  = 10_000_000
      ma.mtm_pnl           = 0
      ma.realized_pnl      = 0
    end
  end

  it "places, modifies, and cancels orders with proper validation and state transitions" do
    # 1. Place a valid order
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE',
      side: 'buy',
      order_type: 'LIMIT',
      product_type: 'CNC',
      qty: 100,
      price: 1000
    })

    expect(order.status).to eq('OPEN')
    expect(order.order_status_transitions.last.to_status).to eq('OPEN')

    # 2. Modify order before any fill
    modified_order = ModifyOrder.call(order: order, new_qty: 150, new_price: 1005)
    expect(modified_order.qty).to eq(150)
    expect(modified_order.price).to eq(1005)
    expect(modified_order.status).to eq('OPEN')
    expect(modified_order.order_status_transitions.last.reason).to include('qty=150')

    # 3. Reject invalid order (LIMIT without price)
    rejected_order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE',
      side: 'buy',
      order_type: 'LIMIT',
      product_type: 'CNC',
      qty: 100
    })
    expect(rejected_order.status).to eq('REJECTED')
    expect(rejected_order.order_status_transitions.last.reason).to include('price must be provided')

    # 4. Cancel order
    cancelled_order = CancelOrder.call(order: modified_order)
    expect(cancelled_order.status).to eq('CANCELLED')
    expect(cancelled_order.order_status_transitions.last.to_status).to eq('CANCELLED')

    # 5. Cannot modify a cancelled order
    expect {
      ModifyOrder.call(order: cancelled_order, new_qty: 200)
    }.to raise_error(/Cannot modify order in state: CANCELLED/)

    # 6. Reject invalid lot size (fractional)
    fractional_order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE',
      side: 'buy',
      order_type: 'MARKET',
      product_type: 'CNC',
      qty: 10.5
    })
    expect(fractional_order.status).to eq('REJECTED')
    expect(fractional_order.order_status_transitions.last.reason).to include('whole number')
  end

  it "handles partial fills and cancel after partial fill" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE',
      side: 'buy',
      order_type: 'LIMIT',
      product_type: 'CNC',
      qty: 100,
      price: 1000
    })

    # Simulate a partial fill
    order.partial_fill!
    order.log_transition('OPEN', 'PARTIALLY_FILLED', 'Matched 40 shares')
    
    # We would normally create a PaperTrade here, but we are just testing states
    # Let's mock filled_qty
    allow(order).to receive(:filled_qty).and_return(40)

    # Cancel after partial fill
    CancelOrder.call(order: order)
    expect(order.status).to eq('CANCELLED')
  end
end
