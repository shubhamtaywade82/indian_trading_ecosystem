# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiskLib::CapitalBands do
  let(:bands) { described_class.new }

  describe "#band_for" do
    it "returns band 1 for balance <= 75,000" do
      band = bands.band_for(50_000)
      expect(band[:upto]).to eq(75_000)
      expect(band[:alloc_pct]).to eq(0.30)
    end

    it "returns band 2 for balance 75,001 to 150,000" do
      band = bands.band_for(100_000)
      expect(band[:upto]).to eq(150_000)
      expect(band[:alloc_pct]).to eq(0.25)
    end

    it "returns band 3 for balance 150,001 to 300,000" do
      band = bands.band_for(200_000)
      expect(band[:upto]).to eq(300_000)
      expect(band[:alloc_pct]).to eq(0.20)
    end

    it "returns band 4 for balance > 300,000" do
      band = bands.band_for(500_000)
      expect(band[:upto]).to eq(Float::INFINITY)
      expect(band[:alloc_pct]).to eq(0.20)
    end
  end

  describe "#alloc_pct" do
    it "returns correct allocation percentage per band" do
      expect(bands.alloc_pct(50_000)).to eq(0.30)
      expect(bands.alloc_pct(100_000)).to eq(0.25)
      expect(bands.alloc_pct(200_000)).to eq(0.20)
      expect(bands.alloc_pct(1_000_000)).to eq(0.20)
    end
  end

  describe "#risk_per_trade_pct" do
    it "returns correct risk per trade percentage per band" do
      expect(bands.risk_per_trade_pct(50_000)).to eq(0.050)
      expect(bands.risk_per_trade_pct(100_000)).to eq(0.035)
      expect(bands.risk_per_trade_pct(200_000)).to eq(0.030)
      expect(bands.risk_per_trade_pct(1_000_000)).to eq(0.025)
    end
  end

  describe "#daily_max_loss_pct" do
    it "returns correct daily max loss percentage per band" do
      expect(bands.daily_max_loss_pct(50_000)).to eq(0.050)
      expect(bands.daily_max_loss_pct(100_000)).to eq(0.060)
      expect(bands.daily_max_loss_pct(200_000)).to eq(0.060)
      expect(bands.daily_max_loss_pct(1_000_000)).to eq(0.050)
    end
  end

  describe "custom bands" do
    it "accepts custom bands" do
      custom = [
        { upto: 50_000, alloc_pct: 0.40, risk_per_trade_pct: 0.06, daily_max_loss_pct: 0.06 },
        { upto: Float::INFINITY, alloc_pct: 0.30, risk_per_trade_pct: 0.04, daily_max_loss_pct: 0.05 }
      ]
      custom_bands = described_class.new(custom)
      expect(custom_bands.alloc_pct(25_000)).to eq(0.40)
      expect(custom_bands.alloc_pct(100_000)).to eq(0.30)
    end
  end
end