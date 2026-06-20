module Portfolio
  class Mandate
    attr_reader :max_weight_per_asset, :max_drawdown, :min_cash_buffer_pct

    def initialize(max_weight_per_asset: 0.10, max_drawdown: 0.20, min_cash_buffer_pct: 0.05)
      @max_weight_per_asset = max_weight_per_asset
      @max_drawdown = max_drawdown
      @min_cash_buffer_pct = min_cash_buffer_pct
    end
  end
end
