# frozen_string_literal: true

RSpec.describe Paper::TradeProcessor, type: :service do
  before do
    @account = Account.create!(
      tenant_id: "test", name: "Test", mode: "paper",
      currency: "INR", starting_balance: 1_000_000
    )
  end

  describe "#execute" do
    it "executes a buy order and creates trade lot" do
      trade = Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      expect(trade).to be_a(PaperTrade)
      expect(trade.fill_qty).to eq(100)
      expect(trade.fill_price).to eq(1000)
      expect(trade.side).to eq("buy")

      lot = TradeLot.find_by(account: @account, instrument_id: "RELIANCE", side: "buy")
      expect(lot).to be_present
      expect(lot.original_qty).to eq(100)
      expect(lot.remaining_qty).to eq(100)
      expect(lot.entry_price).to eq(1000)
      expect(lot.status).to eq("open")
    end

    it "executes a sell order and consumes buy lots" do
      # First buy 100 shares
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      # Then sell 60 shares
      trade = Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "sell", qty: 60, price: 1200
      )

      expect(trade).to be_a(PaperTrade)
      expect(trade.side).to eq("sell")
      expect(trade.fill_qty).to eq(60)

      # Check lot consumption
      consumption = LotConsumption.where(closing_trade: trade).first
      expect(consumption).to be_present
      expect(consumption.qty_consumed).to eq(60)
      expect(consumption.realized_pnl).to eq(200 * 60) # (1200-1000)*60 = 12000
    end

    it "is idempotent with client_order_id" do
      client_id = "order-123"

      trade1 = Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000,
        client_order_id: client_id
      )

      trade2 = Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000,
        client_order_id: client_id
      )

      expect(trade1.id).to eq(trade2.id)
      expect(PaperOrder.where(client_order_id: client_id).count).to eq(1)
    end

    it "raises error when selling more than available" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      expect {
        Paper::TradeProcessor.execute(
          account: @account, instrument_id: "RELIANCE",
          side: "sell", qty: 150, price: 1200
        )
      }.to raise_error(/Cannot sell/)
    end

    it "updates ledger entries correctly" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      je = JournalEntry.where(account: @account).last
      expect(je).to be_present
      expect(je.description).to include("BUY")

      cash_entry = LedgerEntry.find_by(account: @account, ledger_account: "cash")
      expect(cash_entry.credit).to eq(100_000) # 100 * 1000
    end
  end
end