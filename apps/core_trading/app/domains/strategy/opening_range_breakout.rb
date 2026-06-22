# frozen_string_literal: true

module Strategy
  # Concrete implementation: Opening Range Breakout (ORB) Strategy.
  # Mark the High/Low of the first 15/30 mins of the trading session.
  # Trigger CE Buy if candle closes above High, or PE Buy if candle closes below Low.
  # Confirms using volume and checks India VIX.
  class OpeningRangeBreakout < Base
    include OptionsHelper

    def initialize(config = {})
      super
      @orb_minutes = config.fetch(:orb_minutes, 15).to_i
      @range_bars_count = config.fetch(:range_bars_count, 3).to_i # Fallback candle count (e.g. 3 x 5m candles)
      @volume_multiple = config.fetch(:volume_multiple, 1.5).to_f
      
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
        Rails.logger.warn("[ORB] Blocked: VIX (#{vix_price}) outside safe trading limits.")
        return signals
      end
      vix_price ||= 15.0

      total_val = portfolio_state[:total_value].to_f
      total_val = 1_000_000.0 if total_val == 0

      market_data_snapshot.each do |underlying_id, candles|
        next if %w[INDIAVIX INDIA_VIX VIX].include?(underlying_id.to_s.upcase)
        next if candles.empty?

        # Identify range candles and post-range candles
        range_candles, post_candles = split_candles(candles)
        next if range_candles.empty? || post_candles.empty?

        range_high = range_candles.map { |c| c[:high] || c[:close] }.max.to_f
        range_low = range_candles.map { |c| c[:low] || c[:close] }.min.to_f
        avg_range_volume = range_candles.map { |c| c[:volume].to_f }.sum / range_candles.length.to_f

        # Inspect the latest candle for a breakout
        latest_candle = post_candles.last
        latest_close = latest_candle[:close].to_f
        latest_volume = latest_candle[:volume].to_f

        direction = 0 # 1: CE, -1: PE
        if latest_close > range_high
          direction = 1
        elsif latest_close < range_low
          direction = -1
        end

        next if direction == 0

        # Volume confirmation
        if latest_volume > 0 && avg_range_volume > 0 && latest_volume < avg_range_volume * @volume_multiple
          Rails.logger.warn("[ORB] Breakout volume (#{latest_volume}) did not exceed multiplier threshold of #{avg_range_volume * @volume_multiple}")
          next
        end

        # Resolve option contract
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
          confidence: 0.8,
          strategy_name: "OpeningRangeBreakout(#{@strike_style})",
          metadata: {
            underlying_symbol: underlying_id,
            underlying_price: latest_close,
            strike_price: resolved_contract.strike_price,
            expiry_date: resolved_contract.expiry_date,
            option_type: option_type,
            vix: vix_price,
            option_price: option_price,
            target_qty: final_qty,
            target_weight: target_weight,
            stop_loss: stop_loss,
            take_profit: take_profit,
            range_high: range_high,
            range_low: range_low
          }
        )
      end

      signals
    end

    private

    def split_candles(candles)
      # Try time-based splitting first
      sample_candle = candles.first
      if sample_candle[:candle_time] || sample_candle[:timestamp]
        market_open = Time.zone.parse("09:15")
        cutoff = market_open + (@orb_minutes * 60)

        range_c = []
        post_c = []
        candles.each do |c|
          time = c[:candle_time] || c[:timestamp]
          # Normalize time to the same day for comparison
          norm_time = Time.zone.parse(time.strftime("%H:%M"))
          if norm_time <= cutoff
            range_c << c
          else
            post_c << c
          end
        end
        [range_c, post_c]
      else
        # Fallback to index-based splitting
        [candles.first(@range_bars_count), candles.drop(@range_bars_count)]
      end
    end
  end
end
