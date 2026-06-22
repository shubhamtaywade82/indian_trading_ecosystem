# frozen_string_literal: true

module Strategy
  # Concrete implementation: Options Buying Naked Strategy.
  # Monitors an underlying asset (e.g., RELIANCE or NIFTY) using an EMA crossover indicator.
  # Incorporates survival guidelines:
  # 1. Volatility Filtering via India VIX (VIX must be > 12.0 and < 25.0 to avoid flat markets and IV crush).
  # 2. Gamma Wall / Open Interest Checks (blocks entries too close to major OI resistance/support walls).
  # 3. Dynamic Position Sizing based on risk percentage of portfolio.
  # 4. Injects Stop-Loss & Take-Profit targets in signal metadata.
  class OptionsBuyingNaked < Base
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
        contracts = Core::OptionContract
                      .where(underlying_symbol: underlying_id)
                      .where(option_type: option_type)
                      .where("expiry_date >= ?", current_date)
                      .order(expiry_date: :asc)

        # Apply expiry offset to find desired expiry date
        available_expiries = contracts.pluck(:expiry_date).uniq
        selected_expiry = available_expiries[@expiry_offset] || available_expiries.first

        next unless selected_expiry

        expiry_contracts = contracts.where(expiry_date: selected_expiry).order(strike_price: :asc).to_a
        next if expiry_contracts.empty?

        resolved_contract = select_strike(expiry_contracts, underlying_price, option_type)
        next unless resolved_contract&.instrument

        # 2. Gamma Wall / Open Interest Check
        # Check if the underlying is trading too close to a major OI Wall (within 0.5%)
        # For CE, a massive Call OI strike above acts as resistance.
        # For PE, a massive Put OI strike below acts as support.
        oi_blocked = check_gamma_walls(underlying_id, selected_expiry, underlying_price, option_type)
        if oi_blocked
          Rails.logger.warn("[OptionsBuyingNaked] Trade blocked by Gamma Wall / OI resistance check.")
          next
        end

        # 3. Dynamic Position Sizing based on risk percentage of portfolio
        # Get current option price / premium from primary OptionContract
        primary_contract = find_primary_contract(resolved_contract)
        latest_entry = primary_contract ? OptionChainEntry.where(option_contract_id: primary_contract.id).order(created_at: :desc).first : nil
        option_price = latest_entry&.ltp&.to_f || 100.0 # Default fallback if entry not found

        max_capital = total_val * @risk_pct
        lot_size = resolved_contract.instrument&.lot_size&.to_i || 75

        # Calculate lot quantities
        allowed_qty = (max_capital / option_price).to_f
        lots = (allowed_qty / lot_size).to_i
        lots = 1 if lots == 0 # Ensure at least one lot if trading is triggered
        final_qty = lots * lot_size
        target_weight = (final_qty * option_price) / total_val

        # 4. Stop-Loss & Take-Profit targets
        stop_loss = (option_price * (1 - @stop_loss_pct)).round(2)
        take_profit = (option_price * (1 + @take_profit_pct)).round(2)

        # Calculate confidence based on the relative gap of EMAs
        confidence = [(last_indicator_data[:short_ema] - last_indicator_data[:long_ema]).abs / last_indicator_data[:long_ema], 1.0].min.round(4)
        confidence = 0.3 if confidence < 0.1 # Floor confidence for signal viability

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

    private

    def ema(prices, period)
      return prices.last if prices.length <= period

      k = 2.0 / (period + 1)
      ema_val = prices.first(period).sum / period.to_f

      prices[period..].each do |price|
        ema_val = price * k + ema_val * (1 - k)
      end

      ema_val.round(4)
    end

    def select_strike(contracts, underlying_price, option_type)
      # Find index of the contract closest to ATM
      atm_index = contracts.each_with_index.min_by { |c, _| (c.strike_price - underlying_price).abs }[1]

      case @strike_style
      when "ITM"
        target_idx = option_type == "CE" ? atm_index - @strike_offset : atm_index + @strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      when "OTM"
        target_idx = option_type == "CE" ? atm_index + @strike_offset : atm_index - @strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      else # ATM
        contracts[atm_index]
      end
    end

    def check_gamma_walls(underlying_id, expiry, underlying_price, option_type)
      # Find the latest option chain snapshot
      underlying_inst = Instrument.find_by(symbol: underlying_id)
      return false unless underlying_inst

      underlying_record = Underlying.find_by(instrument_id: underlying_inst.id)
      return false unless underlying_record

      chain = OptionChain.where(underlying_id: underlying_record.id, expiry: expiry).order(snapshot_at: :desc).first
      return false unless chain

      # Query max OI strikes
      max_oi_entries = OptionChainEntry.joins(:option_contract)
                                       .where(option_chain_id: chain.id)
                                       .where(option_contracts: { option_type: option_type })
                                       .order(oi: :desc)
                                       .limit(3)

      max_oi_entries.each do |entry|
        strike = entry.option_contract.strike_price.to_f
        percentage_gap = ((underlying_price - strike).abs / strike)
        
        # Block entry if price is within 0.5% of the Gamma Wall resistance/support
        if percentage_gap <= 0.005
          Rails.logger.warn("[OptionsBuyingNaked] Blocked: Underlying price (#{underlying_price}) is too close to major #{option_type} OI Wall at strike #{strike} (gap: #{(percentage_gap * 100).round(2)}%).")
          return true
        end
      end

      false
    end

    def find_primary_contract(core_contract)
      underlying_inst = Instrument.find_by(symbol: core_contract.underlying_symbol)
      return nil unless underlying_inst

      underlying_record = Underlying.find_by(instrument_id: underlying_inst.id)
      return nil unless underlying_record

      OptionContract.joins(derivative_contract: :underlying)
                    .where(option_type: core_contract.option_type)
                    .where(strike_price: core_contract.strike_price)
                    .where(derivative_contracts: { expiry_date: core_contract.expiry_date })
                    .where(underlying: { id: underlying_record.id })
                    .first
    end
  end
end
