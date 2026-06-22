module Risk
  class PreTradeGuard
    # Pre-trade risk checks at the Core level (before any order reaches a broker/paper engine).
    # This is separate from the PaperRiskEngine which is broker-specific.
    # Core Risk = portfolio-level, mandate-level, strategy-level limits.

    def self.check(order:, portfolio_state:, mandate:)
      checks = [
        check_max_notional(order, portfolio_state, mandate),
        check_mandate_weight(order, portfolio_state, mandate),
        check_drawdown(order, portfolio_state, mandate)
      ]

      failure = checks.find { |c| !c[:pass] }
      return failure if failure

      { pass: true }
    end

    def self.check_drawdown(order, portfolio_state, mandate)
      drawdown = portfolio_state[:drawdown].to_f
      if drawdown > mandate.max_drawdown
        return {
          pass: false,
          code: 'MAX_DRAWDOWN_BREACH',
          reason: "Portfolio drawdown #{(drawdown * 100).round(1)}% exceeds max drawdown of #{(mandate.max_drawdown * 100).round(1)}%"
        }
      end
      { pass: true }
    end

    def self.check_mandate_weight(order, portfolio_state, mandate)
      return { pass: true } unless order[:side] == 'buy'

      instrument = order[:instrument_id]
      price = order[:price] || 0
      qty = order[:qty]
      order_value = price * qty

      total_portfolio_value = portfolio_state[:total_value].to_f
      return { pass: true } if total_portfolio_value == 0

      current_weight = (portfolio_state.dig(:positions, instrument, :value).to_f) / total_portfolio_value
      additional_weight = order_value / total_portfolio_value
      projected_weight = current_weight + additional_weight

      if projected_weight > mandate.max_weight_per_asset
        return {
          pass: false,
          code: 'MANDATE_WEIGHT_BREACH',
          reason: "#{instrument} would be #{(projected_weight * 100).round(1)}% of portfolio, " \
                  "exceeding mandate max of #{(mandate.max_weight_per_asset * 100).round(1)}%"
        }
      end

      { pass: true }
    end

    def self.check_max_notional(order, portfolio_state, mandate)
      # Guard against fat finger — single order > 25% of total portfolio
      max_single_order_pct = 0.25
      order_value = (order[:price] || 0) * order[:qty]
      total_portfolio_value = portfolio_state[:total_value].to_f
      return { pass: true } if total_portfolio_value == 0

      if order_value / total_portfolio_value > max_single_order_pct
        return {
          pass: false,
          code: 'NOTIONAL_TOO_LARGE',
          reason: "Single order notional exceeds #{(max_single_order_pct * 100).round}% of portfolio"
        }
      end

      { pass: true }
    end
  end
end
