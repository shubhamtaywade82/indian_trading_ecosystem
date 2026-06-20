require 'rails_helper'

RSpec.describe "Phase 5: Portfolio Risk Engine & Kill Switches", type: :model do
  let!(:account) { Account.create!(tenant_id: "t1", mode: "paper", name: "Test Paper Account") }

  before do
    JournalEntry.transaction do
      j = JournalEntry.create!(account: account, reference_type: 'deposit', reference_id: 1, description: 'Initial Deposit')
      j.ledger_entries.create!(account: account, ledger_account: 'cash', debit: 100_000)
      j.ledger_entries.create!(account: account, ledger_account: 'equity', credit: 100_000)
    end
    
    MarginAccount.create!(
      account_id: account.id,
      cash_balance: 100_000,
      blocked_margin: 0,
      available_margin: 100_000,
      mtm_pnl: 0,
      realized_pnl: 0
    )
  end

  it "rejects order if portfolio kill switch is active" do
    PaperRiskProfile.create!(account_id: account.id, status: 'HALTED')

    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 10
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('KILL_SWITCH')
  end

  it "rejects order if strategy kill switch is active" do
    PaperRiskProfile.create!(account_id: account.id, strategy_id: 'SWING_V1', status: 'HALTED')

    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 10, strategy_id: 'SWING_V1'
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('KILL_SWITCH: Strategy SWING_V1 is halted')
  end

  it "accepts order if strategy is active but another is halted" do
    PaperRiskProfile.create!(account_id: account.id, strategy_id: 'SWING_V1', status: 'HALTED')

    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 10, strategy_id: 'MOMENTUM_V1', price: 1500
    })

    expect(order.status).to eq('OPEN')
  end

  it "rejects order if daily loss is breached" do
    profile = PaperRiskProfile.create!(account_id: account.id, max_daily_loss: 5000, status: 'ACTIVE')
    ma = MarginAccount.find_by(account_id: account.id)
    ma.update!(mtm_pnl: -6000) # Simulating a big intraday drop

    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 10, price: 1500
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('Max daily loss exceeded')
    
    # It should also trigger the Kill Switch!
    expect(profile.reload.status).to eq('HALTED')
  end

  it "rejects order if position size limit is exceeded" do
    PaperRiskProfile.create!(account_id: account.id, max_position_size: 10000, status: 'ACTIVE')

    # Trying to buy 15,000 worth (10 * 1500)
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 10, price: 1500
    })

    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('Max position size exceeded')
  end
  
  it "rejects order if symbol exposure is breached" do
    # 10% max symbol exposure on 100k account = 10k max
    PaperRiskProfile.create!(account_id: account.id, max_symbol_exposure_pct: 0.10, status: 'ACTIVE')
    
    # Assuming inventory already has 8k worth
    JournalEntry.transaction do
      j = JournalEntry.create!(account: account, reference_type: 'trade', reference_id: 99, description: 'Simulate holding')
      j.ledger_entries.create!(account: account, ledger_account: 'inventory:RELIANCE', debit: 8000)
      j.ledger_entries.create!(account: account, ledger_account: 'cash', credit: 8000)
    end
    
    # Trying to buy 5k more (total 13k -> > 10% of 100k)
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT', product_type: 'CNC', qty: 5, price: 1000
    })
    
    expect(order.status).to eq('REJECTED')
    expect(order.order_status_transitions.last.reason).to include('Symbol exposure limit exceeded')
  end
end
