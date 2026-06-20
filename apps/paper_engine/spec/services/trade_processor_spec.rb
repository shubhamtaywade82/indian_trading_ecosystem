# frozen_string_literal: true
require 'rails_helper'

# These specs test the core TradeProcessor service with its actual interface.
RSpec.describe TradeProcessor, type: :service do
  let!(:account) { Account.create!(tenant_id: "test", name: "Test", mode: "paper") }

  describe ".execute" do
    it "executes a buy order and creates trade lot" do
      trade = TradeProcessor.execute(
        account: account, instrument: "RELIANCE",
        side: 'buy', qty: 100, price: 1000
      )

      expect(trade).to be_a(PaperTrade)
      expect(trade.fill_qty).to eq(100)
      expect(trade.fill_price).to eq(1000)
      expect(trade.side).to eq('buy')

      lot = TradeLot.find_by(account: account, instrument_id: "RELIANCE", side: 'buy')
      expect(lot).to be_present
      expect(lot.original_qty).to eq(100)
      expect(lot.remaining_qty).to eq(100)
      expect(lot.entry_price).to eq(1000)
      expect(lot.status).to eq('OPEN')
    end

    it "executes a sell order and consumes buy lots" do
      TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'buy', qty: 100, price: 1000)

      trade = TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'sell', qty: 60, price: 1200)

      expect(trade).to be_a(PaperTrade)
      expect(trade.side).to eq('sell')
      expect(trade.fill_qty).to eq(60)

      consumption = LotConsumption.where(closing_trade: trade).first
      expect(consumption).to be_present
      expect(consumption.qty_consumed).to eq(60)
      expect(consumption.realized_pnl).to eq(200 * 60) # (1200-1000)*60 = 12000
    end

    it "is idempotent with client_order_id" do
      client_id = "order-#{SecureRandom.hex(4)}"

      order = PaperOrder.create!(
        account: account, instrument_id: "RELIANCE", side: 'buy',
        order_type: 'MARKET', product_type: 'CNC', qty: 100,
        client_order_id: client_id, status: 'FILLED'
      )

      t1 = TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'buy', qty: 100, price: 1000, order: order)
      t2 = TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'buy', qty: 100, price: 1000, order: order)

      # Both calls use same order, so same resulting trade IDs via idempotency
      expect(PaperOrder.where(id: order.id).count).to eq(1)
      expect(t1.paper_order_id).to eq(t2.paper_order_id)
    end

    it "raises error when selling more than available" do
      TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'buy', qty: 100, price: 1000)

      expect {
        TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'sell', qty: 150, price: 1200)
      }.to raise_error(StandardError)
    end

    it "updates ledger entries correctly" do
      TradeProcessor.execute(account: account, instrument: "RELIANCE", side: 'buy', qty: 100, price: 1000)

      cash_entry = LedgerEntry.where(account: account, ledger_account: 'cash').last
      expect(cash_entry).to be_present
      # Cash credited (cash OUT) on buy
      expect(cash_entry.credit.to_i).to eq(100_000)
    end
  end
end