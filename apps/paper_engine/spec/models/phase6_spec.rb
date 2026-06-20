require 'rails_helper'

RSpec.describe "Phase 6: Portfolio Lifecycle, Charges & Corporate Actions", type: :model do
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
    
    # Generic Charge Profile
    ChargeProfile.create!(
      broker: 'paper-generic',
      product_type: 'CNC',
      stt_pct: 0.001,
      gst_pct: 0.18,
      exchange_pct: 0.0000325,
      sebi_pct: 0.000001,
      stamp_pct: 0.00015,
      brokerage_flat: 20.0
    )
  end

  it "deducts charges and creates cashflows on buy trade" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'RELIANCE', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 10, price: 2500
    })
    
    MatchingEngine.process_tick({ instrument_id: 'RELIANCE', ltp: 2500, volume: 100, time: Time.current })
    
    trade = PaperTrade.find_by(paper_order_id: order.id)
    
    # Verify charges were posted
    charges = JournalEntry.where(reference_type: 'trade_charges', reference_id: trade.id).first
    expect(charges).not_to be_nil
    
    # Brokerage = 20, STT = 25 (10*2500 * 0.001)
    expect(charges.ledger_entries.where(ledger_account: 'expense:brokerage').first.debit.to_f).to eq(20.0)
    expect(charges.ledger_entries.where(ledger_account: 'expense:stt').first.debit.to_f).to eq(25.0)
    
    # Cash flow created
    cf = PortfolioCashflow.where(flow_type: 'charges', reference_id: trade.id.to_s).first
    expect(cf).not_to be_nil
    expect(cf.amount).to be < 0
  end

  it "creates and processes settlement lots" do
    order = PlaceOrder.call(account: account, payload: {
      instrument_id: 'INFY', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 50, price: 1000
    })
    
    MatchingEngine.process_tick({ instrument_id: 'INFY', ltp: 1000, volume: 50, time: Time.current })

    trade = PaperTrade.find_by(paper_order_id: order.id)
    lot = SettlementLot.find_by(trade_id: trade.id)
    
    expect(lot).not_to be_nil
    expect(lot.status).to eq('PENDING')
    expect(lot.settlement_date).to eq(trade.exchange_ts.to_date + 1.day)
    
    # Process settlement
    Paper::Accounting::SettlementEngine.process_settlements!(lot.settlement_date)
    expect(lot.reload.status).to eq('SETTLED')
  end

  it "handles dividends correctly" do
    trade = PaperTrade.create!(
      paper_order: PaperOrder.create!(account: account, instrument_id: 'TCS', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, client_order_id: SecureRandom.uuid),
      account: account, instrument_id: 'TCS', side: 'buy', fill_qty: 100, fill_price: 3000, fill_value: 300_000, exchange_ts: 2.days.ago
    )
    TradeLot.create!(
      account: account, instrument_id: 'TCS', opening_trade: trade, side: 'buy', original_qty: 100, remaining_qty: 100, entry_price: 3000, status: 'OPEN'
    )
    
    action = CorporateActionEvent.create!(
      action_type: 'DIVIDEND', ex_date: Date.today, instrument_id: 'TCS', ratio_or_amount: 20.0
    )
    
    Paper::Accounting::CorporateActionEngine.process_all!(Date.today)
    
    # Dividend = 100 * 20 = 2000
    ma = MarginAccount.find_by(account_id: account.id)
    expect(ma.cash_balance.to_f).to eq(102_000.0) # 100k initial + 2k div
    
    cf = PortfolioCashflow.where(flow_type: 'dividend').first
    expect(cf.amount.to_f).to eq(2000.0)
  end

  it "handles splits correctly" do
    trade = PaperTrade.create!(
      paper_order: PaperOrder.create!(account: account, instrument_id: 'SPLIT_STOCK', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, client_order_id: SecureRandom.uuid),
      account: account, instrument_id: 'SPLIT_STOCK', side: 'buy', fill_qty: 100, fill_price: 1000, fill_value: 100_000, exchange_ts: 2.days.ago
    )
    lot = TradeLot.create!(
      account: account, instrument_id: 'SPLIT_STOCK', opening_trade: trade, side: 'buy', original_qty: 100, remaining_qty: 100, entry_price: 1000, status: 'OPEN'
    )
    
    action = CorporateActionEvent.create!(
      action_type: 'SPLIT', ex_date: Date.today, instrument_id: 'SPLIT_STOCK', ratio_or_amount: 5.0 # 1:5 split
    )
    
    Paper::Accounting::CorporateActionEngine.process_all!(Date.today)
    
    lot.reload
    expect(lot.remaining_qty.to_f).to eq(500.0)
    expect(lot.entry_price.to_f).to eq(200.0) # 1000 / 5
  end

  it "calculates and accrues taxes on lot consumption" do
    # STCG scenario
    buy_trade = PaperTrade.create!(
      paper_order: PaperOrder.create!(account: account, instrument_id: 'TAX_STOCK', side: 'buy', order_type: 'MARKET', product_type: 'CNC', qty: 100, client_order_id: SecureRandom.uuid),
      account: account, instrument_id: 'TAX_STOCK', side: 'buy', fill_qty: 100, fill_price: 1000, fill_value: 100_000, exchange_ts: 10.days.ago
    )
    lot = TradeLot.create!(
      account: account, instrument_id: 'TAX_STOCK', opening_trade: buy_trade, side: 'buy', original_qty: 100, remaining_qty: 100, entry_price: 1000, status: 'OPEN'
    )
    
    sell_trade = PaperTrade.create!(
      paper_order: PaperOrder.create!(account: account, instrument_id: 'TAX_STOCK', side: 'sell', order_type: 'MARKET', product_type: 'CNC', qty: 100, client_order_id: SecureRandom.uuid),
      account: account, instrument_id: 'TAX_STOCK', side: 'sell', fill_qty: 100, fill_price: 1200, fill_value: 120_000, exchange_ts: 1.day.ago
    )
    
    consumption = LotConsumption.create!(
      trade_lot: lot, closing_trade: sell_trade, qty_consumed: 100, exit_price: 1200, realized_pnl: 20000, costing_method: 'FIFO'
    )
    
    Paper::Accounting::TaxEngine.handle_consumption(consumption)
    
    tax_journal = JournalEntry.where(reference_type: 'tax_liability').first
    expect(tax_journal).not_to be_nil
    
    tax_expense = tax_journal.ledger_entries.where(ledger_account: 'expense:tax:stcg').first
    expect(tax_expense).not_to be_nil
    expect(tax_expense.debit.to_f).to eq(4000.0) # 20% of 20000 STCG
  end
end
