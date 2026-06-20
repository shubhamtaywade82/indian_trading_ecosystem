class Runtime
  class ReplayRuntime
    def self.call(runtime)
      Projections::Position.where(runtime: runtime).delete_all
      Projections::Fund.where(runtime: runtime).delete_all
      Projections::Holding.where(runtime: runtime).delete_all

      Trades::Trade.where(runtime: runtime).order(:executed_at, :id).find_each do |trade|
        Projections::PositionProjector.call(trade)
        Projections::FundsProjector.call(trade)
        Projections::HoldingProjector.call(trade)
      end

      true
    end
  end
end
