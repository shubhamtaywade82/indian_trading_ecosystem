# frozen_string_literal: true

module TradingSystem
  class Supervisor
    def initialize
      @services = {}
      @mutex = Mutex.new
      @running = false
    end

    def register(name, instance)
      @services[name.to_sym] = instance
    end

    def running?
      @mutex.synchronize { @running }
    end

    def start_all
      @mutex.synchronize do
        return if @running

        @services.each do |name, service|
          service.start
          Rails.logger.info("[Supervisor] Started #{name}")
        rescue StandardError => e
          Rails.logger.error("[Supervisor] Failed starting #{name}: #{e.message}")
        end

        @running = true
      end
    end

    def stop_all
      @mutex.synchronize do
        return unless @running

        @services.reverse_each do |name, service|
          service.stop
          Rails.logger.info("[Supervisor] Stopped #{name}")
        rescue StandardError => e
          Rails.logger.error("[Supervisor] Failed stopping #{name}: #{e.message}")
        end

        @running = false
      end
    end
  end
end
