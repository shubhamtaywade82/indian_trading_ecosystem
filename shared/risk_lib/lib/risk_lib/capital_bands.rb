# frozen_string_literal: true

module RiskLib
  class CapitalBands
    DEFAULT_BANDS = [
      { upto: 75_000,   alloc_pct: 0.30, risk_per_trade_pct: 0.050, daily_max_loss_pct: 0.050 },
      { upto: 150_000,  alloc_pct: 0.25, risk_per_trade_pct: 0.035, daily_max_loss_pct: 0.060 },
      { upto: 300_000,  alloc_pct: 0.20, risk_per_trade_pct: 0.030, daily_max_loss_pct: 0.060 },
      { upto: Float::INFINITY, alloc_pct: 0.20, risk_per_trade_pct: 0.025, daily_max_loss_pct: 0.050 }
    ].freeze

    def initialize(bands = DEFAULT_BANDS)
      @bands = bands.sort_by { |b| b[:upto] }
    end

    def band_for(balance)
      @bands.find { |b| balance <= b[:upto] } || @bands.last
    end

    def alloc_pct(balance)
      band_for(balance)[:alloc_pct]
    end

    def risk_per_trade_pct(balance)
      band_for(balance)[:risk_per_trade_pct]
    end

    def daily_max_loss_pct(balance)
      band_for(balance)[:daily_max_loss_pct]
    end
  end
end