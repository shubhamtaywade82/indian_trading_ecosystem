module Risk
  class RiskEngine
    def self.evaluate(runtime, params)
      strategy_id = params[:strategy_id]
      
      # 1. Check if strategy is stopped
      if strategy_id
        strategy = Strategy.find_by(id: strategy_id)
        return { success: false, reason: 'STRATEGY_STOPPED' } if strategy&.status == 'STOPPED'
      end

      # 2. Daily Loss Engine
      dl = DailyLossEngine.evaluate(runtime.id, strategy_id)
      if !dl[:success]
        KillSwitch.activate!(runtime.id, strategy_id, dl[:reason])
        return dl
      end

      # 3. Drawdown Engine
      dd = DrawdownEngine.evaluate(runtime.id, strategy_id)
      if !dd[:success]
        KillSwitch.activate!(runtime.id, strategy_id, dd[:reason])
        return dd
      end

      # 4. Exposure Engine
      exp = ExposureEngine.evaluate(runtime.id, strategy_id, params)
      if !exp[:success]
        return exp
      end

      { success: true }
    end
  end
end
