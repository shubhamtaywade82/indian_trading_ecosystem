module Strategy
  class SignalGenerator
    def initialize(strategies = [])
      @strategies = strategies
    end

    # Run all strategies and collect signals
    def run!(market_data_snapshot, current_portfolio)
      signals = []
      
      @strategies.each do |strategy|
        begin
          strategy_signals = strategy.evaluate(market_data_snapshot, current_portfolio)
          signals.concat(Array(strategy_signals))
        rescue StandardError => e
          # Log failure but continue with other strategies
          Rails.logger.error("Strategy \#{strategy.name} failed: \#{e.message}")
        end
      end
      
      signals
    end
  end
end
