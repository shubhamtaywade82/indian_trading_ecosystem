# frozen_string_literal: true

module DomainModels
  class EventBus
    include Singleton

    def initialize
      @subscribers = Concurrent::Hash.new { |h, k| h[k] = [] }
      @mutex = Mutex.new
    end

    def subscribe(topic, &block)
      @mutex.synchronize do
        @subscribers[topic.to_sym] << block
      end
    end

    def publish(topic, payload = nil)
      handlers = @subscribers[topic.to_sym] || []
      handlers.each do |handler|
        begin
          handler.call(payload)
        rescue StandardError => e
          # Log but don't crash other subscribers
          warn "[EventBus] Handler error for #{topic}: #{e.message}"
        end
      end
    end

    def clear(topic = nil)
      @mutex.synchronize do
        if topic
          @subscribers.delete(topic.to_sym)
        else
          @subscribers.clear
        end
      end
    end
  end
end