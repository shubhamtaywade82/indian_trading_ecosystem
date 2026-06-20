module Strategy
  class Base
    attr_reader :name, :config

    def initialize(config = {})
      @name = self.class.name.demodulize
      @config = config
    end

    # Should return an array of Strategy::Signal objects
    def evaluate(market_data, portfolio_state)
      raise NotImplementedError, "\#{self.class} must implement #evaluate"
    end
  end
end
