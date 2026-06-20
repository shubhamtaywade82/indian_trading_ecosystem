# frozen_string_literal: true

module RiskLib
  class PositionSizer
    def initialize(capital_bands: CapitalBands.new)
      @bands = capital_bands
    end

    def fixed_fractional(balance:, entry_price:, stop_loss_price:, risk_pct: nil)
      risk_pct ||= @bands.risk_per_trade_pct(balance)
      risk_capital = balance * risk_pct
      per_unit_risk = (entry_price - stop_loss_price).abs
      return 0 if per_unit_risk <= 0

      quantity = (risk_capital / per_unit_risk).to_i
      [quantity, 1].max
    end

    def fixed_amount(balance:, entry_price:, stop_loss_price:, risk_amount:)
      per_unit_risk = (entry_price - stop_loss_price).abs
      return 0 if per_unit_risk <= 0

      quantity = (risk_amount / per_unit_risk).to_i
      [quantity, 1].max
    end

    def option_lots(balance:, lot_size:, lot_cost:, risk_pct: nil)
      risk_pct ||= @bands.risk_per_trade_pct(balance)
      risk_capital = balance * risk_pct
      max_lots_by_risk = (risk_capital / lot_cost).to_i
      [max_lots_by_risk, 1].max
    end
  end
end