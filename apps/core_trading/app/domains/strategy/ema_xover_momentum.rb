module Strategy
  # Concrete implementation: Crossover Momentum Strategy.
  # Generates a BUY signal when short EMA crosses above long EMA.
  # Generates a SELL signal when short EMA crosses below long EMA.
  class EmaXoverMomentum < Base
    def initialize(config = {})
      super
      @short_period = config.fetch(:short_period, 9)
      @long_period  = config.fetch(:long_period, 21)
      @min_confidence_threshold = config.fetch(:min_confidence_threshold, 0.3)
    end

    def evaluate(market_data_snapshot, _portfolio_state)
      signals = []

      market_data_snapshot.each do |instrument_id, candles|
        next if candles.length < @long_period + 2

        prices     = candles.map { |c| c[:close] }
        last_signal = nil

        # Walk through all bars starting from long_period+1 to detect crossover at each bar
        (@long_period..prices.length - 1).each do |i|
          slice      = prices[0..i]
          prev_slice = prices[0..(i - 1)]

          short_ema  = ema(slice, @short_period)
          long_ema   = ema(slice, @long_period)
          prev_short = ema(prev_slice, @short_period)
          prev_long  = ema(prev_slice, @long_period)

          # Golden cross — short crosses above long
          if prev_short <= prev_long && short_ema > long_ema
            confidence = [(short_ema - long_ema) / long_ema, 1.0].min.round(4)
            last_signal = Signal.new(
              instrument_id: instrument_id,
              direction:     1,
              confidence:    confidence,
              strategy_name: "EmaXover(#{@short_period}/#{@long_period})",
              metadata:      { short_ema: short_ema, long_ema: long_ema, bar: i }
            )
          end

          # Death cross — short crosses below long
          if prev_short >= prev_long && short_ema < long_ema
            confidence = [(long_ema - short_ema) / long_ema, 1.0].min.round(4)
            last_signal = Signal.new(
              instrument_id: instrument_id,
              direction:     -1,
              confidence:    confidence,
              strategy_name: "EmaXover(#{@short_period}/#{@long_period})",
              metadata:      { short_ema: short_ema, long_ema: long_ema, bar: i }
            )
          end
        end

        # Emit only the most recent signal (avoids re-emitting historical crosses)
        signals << last_signal if last_signal
      end

      signals
    end

    private

    def ema(prices, period)
      return prices.last if prices.length <= period

      k = 2.0 / (period + 1)
      # Start with SMA as seed
      ema_val = prices.first(period).sum / period.to_f

      prices[period..].each do |price|
        ema_val = price * k + ema_val * (1 - k)
      end

      ema_val.round(4)
    end
  end
end
