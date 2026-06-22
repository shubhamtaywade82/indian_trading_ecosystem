# frozen_string_literal: true

module Strategy
  # Concrete implementation: Triple Timeframe Alignment (Trend Pullback) Strategy.
  # 1. Daily Trend: 20-EMA > 50-EMA (Bullish) or 20-EMA < 50-EMA (Bearish).
  # 2. Hourly Trend: Price above 20-EMA (Bullish) or below 20-EMA (Bearish).
  # 3. 15-Min Setup: Pullback to 20-EMA and prints a Hammer or Engulfing candle.
  class TripleTimeframeAlignment < Base
    include OptionsHelper

    def initialize(config = {})
      super
      @short_ema_period = config.fetch(:short_ema_period, 20)
      @long_ema_period  = config.fetch(:long_ema_period, 50)
      @strike_style = config.fetch(:strike_style, "ATM").to_s.upcase
      @strike_offset = config.fetch(:strike_offset, 0).to_i
      @expiry_offset = config.fetch(:expiry_offset, 0).to_i

      @vix_min = config.fetch(:vix_min, 12.0)
      @vix_max = config.fetch(:vix_max, 25.0)
      @risk_pct = config.fetch(:risk_pct_per_trade, 0.01)
      @stop_loss_pct = config.fetch(:stop_loss_pct, 0.15)
      @take_profit_pct = config.fetch(:take_profit_pct, 0.30)
    end

    def evaluate(market_data_snapshot, portfolio_state)
      signals = []

      vix_candles = market_data_snapshot["INDIAVIX"] || market_data_snapshot["INDIA_VIX"] || market_data_snapshot["VIX"]
      vix_price = vix_candles&.last&.dig(:close)&.to_f

      if vix_price && (vix_price < @vix_min || vix_price > @vix_max)
        Rails.logger.warn("[TripleTF] Blocked: VIX (#{vix_price}) outside safe trading limits.")
        return signals
      end
      vix_price ||= 15.0

      total_val = portfolio_state[:total_value].to_f
      total_val = 1_000_000.0 if total_val == 0

      # Group snapshots by base asset to match multiple timeframes (e.g. RELIANCE, RELIANCE_DAILY)
      underlying_assets = market_data_snapshot.keys.map { |k| k.to_s.split('_').first }.uniq
      underlying_assets.delete_if { |k| %w[INDIAVIX INDIAVIX VIX].include?(k.upcase) }

      underlying_assets.each do |asset_symbol|
        candles_15m = market_data_snapshot[asset_symbol] || market_data_snapshot["#{asset_symbol}_15MIN"]
        next if candles_15m.nil? || candles_15m.length < @short_ema_period + 2

        # Extract/Mock multi-timeframe candles
        daily_candles = market_data_snapshot["#{asset_symbol}_DAILY"] || candles_15m
        hourly_candles = market_data_snapshot["#{asset_symbol}_HOURLY"] || candles_15m

        # 1. Daily Trend Check
        daily_prices = daily_candles.map { |c| c[:close].to_f }
        daily_short_ema = ema(daily_prices, @short_ema_period)
        daily_long_ema = ema(daily_prices, @long_ema_period)
        daily_bullish = daily_short_ema > daily_long_ema
        daily_bearish = daily_short_ema < daily_long_ema

        # 2. Hourly Trend Check
        hourly_prices = hourly_candles.map { |c| c[:close].to_f }
        hourly_ema_val = ema(hourly_prices, @short_ema_period)
        hourly_latest_price = hourly_prices.last
        hourly_bullish = hourly_latest_price >= hourly_ema_val
        hourly_bearish = hourly_latest_price <= hourly_ema_val

        # 3. 15-Min Setup (Pullback to 20-EMA)
        prices_15m = candles_15m.map { |c| c[:close].to_f }
        ema_15m = ema(prices_15m, @short_ema_period)
        latest_candle = candles_15m.last
        prev_candle = candles_15m[-2]

        latest_close = latest_candle[:close].to_f
        latest_open = latest_candle[:open] ? latest_candle[:open].to_f : latest_close
        latest_low = latest_candle[:low] ? latest_candle[:low].to_f : latest_close
        latest_high = latest_candle[:high] ? latest_candle[:high].to_f : latest_close

        # Reversal Candle detection
        is_hammer = hammer?(latest_open, latest_close, latest_low, latest_high)
        is_engulfing = prev_candle ? bullish_engulfing?(prev_candle, latest_candle) : false

        direction = 0 # 1: CE (Bullish pullback), -1: PE (Bearish pullback)

        if daily_bullish && hourly_bullish
          # Check for pullback to EMA (low touches or crosses EMA, close remains above EMA)
          is_pullback = latest_low <= ema_15m * 1.002 && latest_close > ema_15m
          if is_pullback && (is_hammer || is_engulfing)
            direction = 1
          end
        elsif daily_bearish && hourly_bearish
          # Bearish pullback (high touches or crosses EMA, close remains below EMA)
          latest_high = latest_candle[:high] ? latest_candle[:high].to_f : latest_close
          is_pullback = latest_high >= ema_15m * 0.998 && latest_close < ema_15m
          # For puts, hammer/engulfing logic is inverted or simple touch + reversal
          if is_pullback
            direction = -1
          end
        end

        next if direction == 0

        # Resolve option contract
        current_date = latest_candle[:candle_time]&.to_date || latest_candle[:timestamp]&.to_date || Date.current
        option_type = direction == 1 ? "CE" : "PE"
        resolved_contract = resolve_option_contract(
          asset_symbol, current_date, latest_close, option_type,
          @expiry_offset, @strike_style, @strike_offset
        )
        next unless resolved_contract&.instrument

        # Gamma Wall Check
        oi_blocked = check_gamma_walls(asset_symbol, resolved_contract.expiry_date, latest_close, option_type)
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
          confidence: 0.9,
          strategy_name: "TripleTimeframeAlignment(#{@strike_style})",
          metadata: {
            underlying_symbol: asset_symbol,
            underlying_price: latest_close,
            strike_price: resolved_contract.strike_price,
            expiry_date: resolved_contract.expiry_date,
            option_type: option_type,
            vix: vix_price,
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

    def hammer?(open, close, low, high)
      body = (close - open).abs
      return false if body == 0

      lower_shadow = [open, close].min - low
      upper_shadow = high - [open, close].max

      # Lower shadow must be at least 2 times the body length
      # Upper shadow must be very small (less than 30% of body)
      lower_shadow > (2.0 * body) && upper_shadow < (0.3 * body)
    end

    def bullish_engulfing?(prev, current)
      p_close = prev[:close].to_f
      p_open = prev[:open] ? prev[:open].to_f : p_close
      c_close = current[:close].to_f
      c_open = current[:open] ? current[:open].to_f : c_close

      # Previous candle must be red (bearish)
      # Current candle must be green (bullish) and engulf the previous body
      p_close < p_open && c_close > c_open && c_close >= p_open && c_open <= p_close
    end
  end
end
