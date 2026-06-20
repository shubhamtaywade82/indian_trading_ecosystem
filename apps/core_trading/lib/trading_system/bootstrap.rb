# frozen_string_literal: true

module TradingSystem
  class Bootstrap
    def self.boot!
      supervisor = Supervisor.new
      supervisor.register(:feed_health, FeedHealthService.new)
      supervisor.register(:pnl_updater, PnlUpdaterService.new)
      supervisor.start_all

      Signal.trap("INT")  { graceful_shutdown(supervisor) }
      Signal.trap("TERM") { graceful_shutdown(supervisor) }

      supervisor
    end

    def self.graceful_shutdown(supervisor)
      Rails.logger.info("[Bootstrap] Graceful shutdown initiated...")
      supervisor.stop_all
      exit!(0)
    end
  end
end
