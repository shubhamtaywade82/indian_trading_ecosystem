# frozen_string_literal: true

require "redis"

module Marketfeed
  class Runner
    def initialize
      @redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
    end

    def start
      puts "[Marketfeed] Starting..."
      puts "[Marketfeed] Connected to Redis at #{ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')}"
      puts "[Marketfeed] WebSocket ingestion would start here"

      loop do
        sleep 30
        puts "[Marketfeed] Heartbeat #{Time.now}"
      end
    end
  end
end