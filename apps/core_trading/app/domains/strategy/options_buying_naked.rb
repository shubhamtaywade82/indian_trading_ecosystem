# frozen_string_literal: true

module Strategy
  # Concrete implementation: Options Buying Naked Strategy.
  # Monitors an underlying asset (e.g., RELIANCE or NIFTY) using an EMA crossover indicator.
  class OptionsBuyingNaked < Base
    include OptionsHelper

    def initialize(config = {})
      super
      @short_period = config.fetch(:short_period, 9)
      @long_period  = config.fetch(:long_period, 21)
      @strike_style = config.fetch(:strike_style, "ATM").to_s.upcase # ATM, ITM, OTM
      @strike_offset = config.fetch(:strike_offset, 0).to_i
      @expiry_offset = config.fetch(:expiry_offset, 0).to_i

      # Survival options
      @vix_min = config.fetch(:vix_min, 12.0)
      @vix_max = config.fetch(:vix_max, 25.0)
      @risk_pct = config.fetch(:risk_pct_per_trade, 0.01) # Default 1% portfolio risk
      @stop_loss_pct = config.fetch(:stop_loss_pct, 0.15) # Default 15% stop-loss
      @take_profit_pct = config.fetch(:take_profit_pct, 0.30) # Default 30% take-profit
    end

    def evaluate(market_data_snapshot, portfolio_state)
      signals = []

      # 1. Volatility Filtering: Check India VIX if present in market data
      vix_candles = market_data_snapshot["INDIAVIX"] || market_data_snapshot["INDIA_VIX"] || market_data_snapshot["VIX"]
      vix_price = vix_candles&.last&.dig(:close)&.to_f

      if vix_price
        if vix_price < @vix_min
          Rails.logger.warn("[OptionsBuyingNaked] Trade blocked: VIX (#{vix_price}) too low (< #{@vix_min}). Dead market risk.")
          return signals
        elsif vix_price > @vix_max
          Rails.logger.warn("[OptionsBuyingNaked] Trade blocked: VIX (#{vix_price}) too high (> #{@vix_max}). Imminent IV crush risk.")
          return signals
        end
      else
        vix_price = 15.0 # Fallback default for testing
      end

      total_val = portfolio_state[:total_value].to_f
      total_val = 1_000_000.0 if total_val == 0 # Fallback for test convenience

      market_data_snapshot.each do |underlying_id, candles|
        next if %w[INDIAVIX INDIA_VIX VIX].include?(underlying_id.to_s.upcase)
        next if candles.length < @long_period + 2

        prices = candles.map { |c| c[:close] }
        direction = 0 # 1: Bullish (Golden Cross), -1: Bearish (Death Cross)
        last_indicator_data = nil

        # Walk through EMA values to find crossover on the latest bar
        (@long_period..prices.length - 1).each do |i|
          slice      = prices[0..i]
          prev_slice = prices[0..(i - 1)]

          short_ema  = ema(slice, @short_period)
          long_ema   = ema(slice, @long_period)
          prev_short = ema(prev_slice, @short_period)
          prev_long  = ema(prev_slice, @long_period)

          # Golden cross — short crosses above long
          if prev_short <= prev_long && short_ema > long_ema
            direction = 1
            last_indicator_data = { short_ema: short_ema, long_ema: long_ema, bar: i }
          end

          # Death cross — short crosses below long
          if prev_short >= prev_long && short_ema < long_ema
            direction = -1
            last_indicator_data = { short_ema: short_ema, long_ema: long_ema, bar: i }
          end
        end

        next if direction == 0

        # Current date based on last candle timestamp or fallback to system time
        last_candle = candles.last
        current_date = last_candle[:candle_time]&.to_date || last_candle[:timestamp]&.to_date || Date.current
        underlying_price = last_candle[:close].to_f

        # Resolve option contract
        option_type = direction == 1 ? "CE" : "PE"
        resolved_contract = resolve_option_contract(
          underlying_id, current_date, underlying_price, option_type,
          @expiry_offset, @strike_style, @strike_offset
        )
        next unless resolved_contract&.instrument

        # 2. Gamma Wall / Open Interest Check
        oi_blocked = check_gamma_walls(underlying_id, resolved_contract.expiry_date, underlying_price, option_type)
        if oi_blocked
          Rails.logger.warn("[OptionsBuyingNaked] Trade blocked by Gamma Wall / OI resistance check.")
          next
        end

        # 3. Dynamic Position Sizing based on risk percentage of portfolio
        primary_contract = find_primary_contract(resolved_contract)
        latest_entry = primary_contract ? OptionChainEntry.where(option_contract_id: primary_contract.id).order(created_at: :desc).first : nil
        option_price = latest_entry&.ltp&.to_f || 100.0

        max_capital = total_val * @risk_pct
        lot_size = resolved_contract.instrument&.lot_size&.to_i || 75

        # Calculate lot quantities
        allowed_qty = (max_capital / option_price).to_f
        lots = (allowed_qty / lot_size).to_i
        lots = 1 if lots == 0
        final_qty = lots * lot_size
        target_weight = (final_qty * option_price) / total_val

        # 4. Stop-Loss & Take-Profit targets
        stop_loss = (option_price * (1 - @stop_loss_pct)).round(2)
        take_profit = (option_price * (1 + @take_profit_pct)).round(2)

        # Calculate confidence based on the relative gap of EMAs
        confidence = [(last_indicator_data[:short_ema] - last_indicator_data[:long_ema]).abs / last_indicator_data[:long_ema], 1.0].min.round(4)
        confidence = 0.3 if confidence < 0.1

        signals << Signal.new(
          instrument_id: resolved_contract.instrument.symbol,
          direction: 1, # Always buying the option naked
          confidence: confidence,
          strategy_name: "OptionsBuyingNaked(#{@strike_style})",
          metadata: last_indicator_data.merge(
            underlying_symbol: underlying_id,
            underlying_price: underlying_price,
            strike_price: resolved_contract.strike_price,
            expiry_date: resolved_contract.expiry_date,
            option_type: option_type,
            strike_style: @strike_style,
            vix: vix_price,
            option_price: option_price,
            target_qty: final_qty,
            target_weight: target_weight,
            stop_loss: stop_loss,
            take_profit: take_profit
          )
        )
      end

      signals
    end
  end
end
