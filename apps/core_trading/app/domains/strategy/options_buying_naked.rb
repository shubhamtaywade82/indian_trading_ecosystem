# frozen_string_literal: true

module Strategy
  # Concrete implementation: Options Buying Naked Strategy.
  # Monitors an underlying asset (e.g., RELIANCE or NIFTY) using an EMA crossover indicator.
  # Generates a BUY signal for an At-the-Money (ATM) or offset Call Option (CE) on golden cross.
  # Generates a BUY signal for an At-the-Money (ATM) or offset Put Option (PE) on death cross.
  class OptionsBuyingNaked < Base
    def initialize(config = {})
      super
      @short_period = config.fetch(:short_period, 9)
      @long_period  = config.fetch(:long_period, 21)
      @strike_style = config.fetch(:strike_style, "ATM").to_s.upcase # ATM, ITM, OTM
      @strike_offset = config.fetch(:strike_offset, 0).to_i
      @expiry_offset = config.fetch(:expiry_offset, 0).to_i
    end

    def evaluate(market_data_snapshot, _portfolio_state)
      signals = []

      market_data_snapshot.each do |underlying_id, candles|
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
        underlying_price = last_candle[:close]

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

        # Calculate confidence based on the relative gap of EMAs
        confidence = [(last_indicator_data[:short_ema] - last_indicator_data[:long_ema]).abs / last_indicator_data[:long_ema], 1.0].min.round(4)
        confidence = 0.3 if confidence < 0.1 # Floor confidence for signal viability

        signals << Signal.new(
          instrument_id: resolved_contract.instrument.symbol,
          direction: 1, # Always buying the option naked (whether CE or PE)
          confidence: confidence,
          strategy_name: "OptionsBuyingNaked(#{@strike_style})",
          metadata: last_indicator_data.merge(
            underlying_symbol: underlying_id,
            underlying_price: underlying_price,
            strike_price: resolved_contract.strike_price,
            expiry_date: resolved_contract.expiry_date,
            option_type: option_type,
            strike_style: @strike_style
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
        # ITM for CE: Strike < Underlying (lower strike)
        # ITM for PE: Strike > Underlying (higher strike)
        target_idx = option_type == "CE" ? atm_index - @strike_offset : atm_index + @strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      when "OTM"
        # OTM for CE: Strike > Underlying (higher strike)
        # OTM for PE: Strike < Underlying (lower strike)
        target_idx = option_type == "CE" ? atm_index + @strike_offset : atm_index - @strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      else # ATM
        contracts[atm_index]
      end
    end
  end
end
