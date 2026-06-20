module Strategy
  class Signal
    attr_reader :instrument_id, :direction, :confidence, :metadata, :generated_at, :strategy_name

    # direction: 1 (BUY), -1 (SELL), 0 (HOLD/FLAT)
    # confidence: 0.0 to 1.0
    def initialize(instrument_id:, direction:, confidence:, strategy_name:, metadata: {})
      @instrument_id = instrument_id
      @direction = direction
      @confidence = confidence
      @strategy_name = strategy_name
      @metadata = metadata
      @generated_at = Time.current
    end

    def buy?
      @direction > 0
    end

    def sell?
      @direction < 0
    end
  end
end
