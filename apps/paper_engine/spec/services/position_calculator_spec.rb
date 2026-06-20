# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Paper::PositionCalculator, type: :service do
  let!(:account) { Account.create!(tenant_id: "test", name: "Test", mode: "paper") }

  def buy(instrument, qty, price)
    TradeProcessor.execute(account: account, instrument: instrument, side: 'buy', qty: qty, price: price)
  end

  def sell(instrument, qty, price)
    TradeProcessor.execute(account: account, instrument: instrument, side: 'sell', qty: qty, price: price)
  end

  describe "#position_for" do
    it "returns zero position for unknown instrument" do
      pos = Paper::PositionCalculator.position_for(account, "UNKNOWN")
      expect(pos[:net_qty]).to eq(0)
      expect(pos[:avg_price]).to eq(0)
      expect(pos[:realized_pnl]).to eq(0)
    end

    it "calculates correct position after buy" do
      buy("RELIANCE", 100, 1000)
      pos = Paper::PositionCalculator.position_for(account, "RELIANCE")
      expect(pos[:net_qty]).to eq(100)
      expect(pos[:avg_price]).to eq(1000)
    end

    it "calculates weighted average for multiple buys" do
      buy("RELIANCE", 100, 1000)
      buy("RELIANCE", 100, 1200)

      pos = Paper::PositionCalculator.position_for(account, "RELIANCE")
      expect(pos[:net_qty]).to eq(200)
      # (100*1000 + 100*1200) / 200 = 1100
      expect(pos[:avg_price]).to eq(1100)
    end

    it "tracks realized P&L after sells" do
      buy("RELIANCE", 100, 1000)
      sell("RELIANCE", 60, 1200)

      pos = Paper::PositionCalculator.position_for(account, "RELIANCE")
      # (1200 - 1000) * 60 = 12000
      expect(pos[:realized_pnl]).to eq(12_000)
      expect(pos[:net_qty]).to eq(40)
    end
  end

  describe "#all_positions" do
    it "returns empty array when no positions" do
      expect(Paper::PositionCalculator.all_positions(account)).to eq([])
    end

    it "returns all open positions" do
      buy("RELIANCE", 100, 1000)
      buy("INFOSYS", 50, 1500)

      positions = Paper::PositionCalculator.all_positions(account)
      expect(positions.size).to eq(2)

      reliance = positions.find { |p| p[:instrument_id] == "RELIANCE" }
      expect(reliance[:net_qty]).to eq(100)

      infosys = positions.find { |p| p[:instrument_id] == "INFOSYS" }
      expect(infosys[:net_qty]).to eq(50)
    end
  end

  describe "#cash_balance" do
    it "returns negative balance (debits from buys) when only buys" do
      buy("RELIANCE", 100, 1000)
      # cash credited = 100_000 out; ledger shows -100_000
      expect(Paper::PositionCalculator.cash_balance(account)).to eq(-100_000)
    end

    it "increases cash (reduces negative) on sell" do
      buy("RELIANCE", 100, 1000)
      sell("RELIANCE", 40, 1200)

      # Cash out: 100_000, Cash in: 48_000 => net: -52_000
      expect(Paper::PositionCalculator.cash_balance(account)).to eq(-52_000)
    end
  end
end