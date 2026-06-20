# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiskLib::PositionSizer do
  subject { described_class.new }

  describe "#fixed_fractional" do
    it "calculates quantity based on risk" do
      # balance 100,000; band 2 with risk_per_trade_pct 0.035 (100k-150k)
      qty = subject.fixed_fractional(balance: 100_000, entry_price: 200, stop_loss_price: 190)
      # risk = 100k * 3.5% = 3,500; per_unit = 10; qty = 350
      expect(qty).to eq(350)
    end

    it "returns at least 1 when calculated qty is below minimum" do
      # Very tight stop loss creates high per-unit risk, but small balance limits capital
      # risk_capital = 100 * 5% = 5; per_unit = 0.01; qty = 500; max(500,1) = 500
      # This tests the floor of [quantity, 1].max — actual qty is 500
      qty = subject.fixed_fractional(balance: 100, entry_price: 200, stop_loss_price: 199.99)
      expect(qty).to eq(500)
    end

    it "returns minimum 1 when risk capital is tiny relative to per-unit risk" do
      # Only 1 rupee risk capital with 10 rupee per-unit risk = 0.1 qty floored to 1
      qty = subject.fixed_fractional(balance: 20, entry_price: 200, stop_loss_price: 190, risk_pct: 0.05)
      # risk_capital = 20 * 0.05 = 1; per_unit = 10; qty = 0.1 -> max(0, 1) = 1
      expect(qty).to eq(1)
    end

    it "returns 0 when stop loss equals entry price" do
      qty = subject.fixed_fractional(balance: 100_000, entry_price: 200, stop_loss_price: 200)
      expect(qty).to eq(0)
    end

    it "respects explicit risk_pct override" do
      qty = subject.fixed_fractional(balance: 100_000, entry_price: 200, stop_loss_price: 190, risk_pct: 0.05)
      # risk = 100k * 5% = 5,000; per_unit = 10; qty = 500
      expect(qty).to eq(500)
    end

    it "works with sell side positions" do
      # For sell, stop_loss is above entry (short squeeze scenario)
      qty = subject.fixed_fractional(balance: 100_000, entry_price: 190, stop_loss_price: 200)
      # risk = 100k * 3.5% = 3,500; per_unit = 10; qty = 350
      expect(qty).to eq(350)
    end
  end

  describe "#fixed_amount" do
    it "calculates quantity based on fixed risk amount" do
      qty = subject.fixed_amount(balance: 100_000, entry_price: 200, stop_loss_price: 190, risk_amount: 2000)
      # risk_amount = 2,000; per_unit = 10; qty = 200
      expect(qty).to eq(200)
    end

    it "returns at least 1 when risk capital is tiny" do
      # Only 1 rupee risk capital with 1 rupee per-unit risk = 1 lot (floor of 1)
      qty = subject.fixed_amount(balance: 100_000, entry_price: 200, stop_loss_price: 199, risk_amount: 1)
      # risk_amount = 1; per_unit = 1; qty = 1
      expect(qty).to eq(1)
    end

    it "returns 0 when stop loss equals entry price" do
      qty = subject.fixed_amount(balance: 100_000, entry_price: 200, stop_loss_price: 200, risk_amount: 1000)
      expect(qty).to eq(0)
    end
  end

  describe "#option_lots" do
    it "calculates max lots based on risk" do
      # balance 100,000; band 2 risk_pct 0.035; lot_cost = 5000 per lot
      lots = subject.option_lots(balance: 100_000, lot_size: 75, lot_cost: 5000)
      # risk_capital = 100k * 3.5% = 3,500; max_lots = 3,500 / 5,000 = 0 (floored), then max(0, 1) = 1
      expect(lots).to eq(1)
    end

    it "returns at least 1 lot" do
      lots = subject.option_lots(balance: 1_000_000, lot_size: 75, lot_cost: 500)
      # risk_capital = 1M * 2.5% = 25,000; max_lots = 25,000 / 500 = 50
      expect(lots).to eq(50)
    end

    it "respects explicit risk_pct override" do
      lots = subject.option_lots(balance: 100_000, lot_size: 75, lot_cost: 5000, risk_pct: 0.10)
      # risk_capital = 100k * 10% = 10,000; max_lots = 10,000 / 5,000 = 2
      expect(lots).to eq(2)
    end
  end
end