# frozen_string_literal: true

module Strategy
  # Concrete implementation: VIX Mean Reversion Expansion Strategy.
  # 1. VIX compression: VIX 20-period percentile was < 20% for 3 bars.
  # 2. VIX breakout: VIX rises > 5% and crosses above its 5-period MA.
  # 3. Direction: CE if underlying close > 20-EMA, PE if underlying close < 20-EMA.
  class VixMeanReversion < Base
    include OptionsHelper

    def initialize(config = {})
      super
      @vix_percentile_threshold = config.fetch(:vix_percentile_threshold, 20.0).to_f
      @vix_compression_bars = config.fetch(:vix_compression_bars, 3).to_i
      @vix_rise_pct = config.fetch(:vix_rise_pct, 0.05).to_f
      @vix_ma_period = config.fetch(:vix_ma_period, 5).to_i
      @underlying_ema_period = config.fetch(:underlying_ema_period, 20).to_i

      @strike_style = config.fetch(:strike_style, "ATM").to_s.upcase
      @strike_offset = config.fetch(:strike_offset, 0).to_i
      @expiry_offset = config.fetch(:expiry_offset, 0).to_i
      @risk_pct = config.fetch(:risk_pct_per_trade, 0.01)
      @stop_loss_pct = config.fetch(:stop_loss_pct, 0.15)
      @take_profit_pct = config.fetch(:take_profit_pct, 0.30)
    end

    def evaluate(market_data_snapshot, portfolio_state)
      signals = []

      # Find VIX candles
      vix_candles = market_data_snapshot["INDIAVIX"] || market_data_snapshot["INDIA_VIX"] || market_data_snapshot["VIX"]
      return signals if vix_candles.nil? || vix_candles.length < 20

      vix_closes = vix_candles.map { |c| c[:close].to_f }
      vix_latest = vix_closes.last
      vix_prev = vix_closes[-2]

      # 1. Verify VIX compression (percentile < threshold for last N bars prior to breakout)
      compressed = true
      (2..@vix_compression_bars + 1).each do |offset|
        idx = vix_closes.length - offset
        history = vix_closes[0..idx]
        percentile = calculate_percentile(history, 20)
        if percentile >= @vix_percentile_threshold
          compressed = false
          break
        end
      end

      return signals unless compressed

      # 2. VIX Breakout (rises > 5% and crosses above its 5-day MA)
      vix_ma = ema(vix_closes, @vix_ma_period)
      vix_rise = (vix_latest - vix_prev) / vix_prev
      vix_crossed_ma = vix_prev <= ema(vix_closes[0..-2], @vix_ma_period) && vix_latest > vix_ma

      return signals unless vix_rise >= @vix_rise_pct && vix_crossed_ma

      # Trigger trades on underlying assets
      total_val = portfolio_state[:total_value].to_f
      total_val = 1_000_000.0 if total_val == 0

      market_data_snapshot.each do |underlying_id, candles|
        next if %w[INDIAVIX INDIA_VIX VIX].include?(underlying_id.to_s.upcase)
        next if candles.length < @underlying_ema_period + 2

        prices = candles.map { |c| c[:close].to_f }
        latest_close = prices.last
        index_ema = ema(prices, @underlying_ema_period)

        # Bullish or Bearish relative to EMA
        direction = latest_close > index_ema ? 1 : -1

        # Resolve option contract
        latest_candle = candles.last
        current_date = latest_candle[:candle_time]&.to_date || latest_candle[:timestamp]&.to_date || Date.current
        option_type = direction == 1 ? "CE" : "PE"
        resolved_contract = resolve_option_contract(
          underlying_id, current_date, latest_close, option_type,
          @expiry_offset, @strike_style, @strike_offset
        )
        next unless resolved_contract&.instrument

        # Gamma Wall Check
        oi_blocked = check_gamma_walls(underlying_id, resolved_contract.expiry_date, latest_close, option_type)
        next if oi_blocked

        # Position Sizing
        primary_contract = find_primary_contract(resolved_contract)
        latest_entry = primary_contract ? OptionChainEntry.where(option_contract_id: primary_contract.id).order(created_at: :desc).first : nil
        option_price = latest_entry&.ltp&.to_f || 100.0

        max_capital = total_val * @risk_pct
        lot_size = resolved_contract.instrument&.lot_size&.to_i || 75

        allowed_qty = (max_capital / option_price).to_f
        lots = (allowed_qty / lot_size).to_i
        lots = 1 if lots == 0
        final_qty = lots * lot_size
        target_weight = (final_qty * option_price) / total_val

        stop_loss = (option_price * (1 - @stop_loss_pct)).round(2)
        take_profit = (option_price * (1 + @take_profit_pct)).round(2)

        signals << Signal.new(
          instrument_id: resolved_contract.instrument.symbol,
          direction: 1,
          confidence: 0.75,
          strategy_name: "VixMeanReversion(#{@strike_style})",
          metadata: {
            underlying_symbol: underlying_id,
            underlying_price: latest_close,
            strike_price: resolved_contract.strike_price,
            expiry_date: resolved_contract.expiry_date,
            option_type: option_type,
            vix: vix_latest,
            option_price: option_price,
            target_qty: final_qty,
            target_weight: target_weight,
            stop_loss: stop_loss,
            take_profit: take_profit
          }
        )
      end

      signals
    end

    private

    def calculate_percentile(history, window)
      slice = history.last(window)
      latest = slice.last
      lower_count = slice.count { |v| v < latest }
      (lower_count / slice.length.to_f) * 100.0
    end
  end
end
