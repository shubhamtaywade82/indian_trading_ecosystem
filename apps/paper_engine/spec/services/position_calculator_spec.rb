# frozen_string_literal: true

RSpec.describe Paper::PositionCalculator, type: :service do
  before do
    @account = Account.create!(
      tenant_id: "test", name: "Test", mode: "paper",
      currency: "INR", starting_balance: 1_000_000
    )
  end

  describe "#for" do
    it "returns zero position for unknown instrument" do
      pos = Paper::PositionCalculator.position_for(@account, "UNKNOWN")
      expect(pos[:net_qty]).to eq(0)
      expect(pos[:avg_price]).to eq(0)
      expect(pos[:realized_pnl]).to eq(0)
    end

    it "calculates correct position after buy" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      pos = Paper::PositionCalculator.position_for(@account, "RELIANCE")
      expect(pos[:net_qty]).to eq(100)
      expect(pos[:avg_price]).to eq(1000)
    end

    it "calculates weighted average for multiple buys" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1200
      )

      pos = Paper::PositionCalculator.position_for(@account, "RELIANCE")
      expect(pos[:net_qty]).to eq(200)
      # (100*1000 + 100*1200) / 200 = 1100
      expect(pos[:avg_price]).to eq(1100)
    end

    it "tracks realized P&L after sells" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "sell", qty: 60, price: 1200
      )

      pos = Paper::PositionCalculator.position_for(@account, "RELIANCE")
      # 60 sold at 1200, cost was 60*1000 = 60000, profit = 72000 - 60000 = 12000
      expect(pos[:realized_pnl]).to eq(12000)
      expect(pos[:net_qty]).to eq(40)
    end
  end

  describe "#all_positions" do
    it "returns empty array when no positions" do
      positions = Paper::PositionCalculator.all_positions(@account)
      expect(positions).to eq([])
    end

    it "returns all open positions" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "INFOSYS",
        side: "buy", qty: 50, price: 1500
      )

      positions = Paper::PositionCalculator.all_positions(@account)
      expect(positions.size).to eq(2)

      reliance_pos = positions.find { |p| p[:instrument_id] == "RELIANCE" }
      expect(reliance_pos[:net_qty]).to eq(100)

      infosys_pos = positions.find { |p| p[:instrument_id] == "INFOSYS" }
      expect(infosys_pos[:net_qty]).to eq(50)
    end
  end

  describe "#cash_balance" do
    it "returns starting balance when no trades" do
      expect(Paper::PositionCalculator.cash_balance(@account)).to eq(1_000_000)
    end

    it "decreases cash on buy" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )

      expect(Paper::PositionCalculator.cash_balance(@account)).to eq(900_000)
    end

    it "increases cash on sell" do
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "buy", qty: 100, price: 1000
      )
      Paper::TradeProcessor.execute(
        account: @account, instrument_id: "RELIANCE",
        side: "sell", qty: 40, price: 1200
      )

      # 1M - 100000 + 48000 = 948000
      expect(Paper::PositionCalculator.cash_balance(@account)).to eq(948_000)
    end
  end
end