# frozen_string_literal: true

module DomainModels
  module Events
    class BaseEvent
      attr_reader :topic, :payload, :timestamp

      def initialize(topic:, payload:)
        @topic = topic
        @payload = payload
        @timestamp = Time.now.utc.iso8601
      end

      def to_h
        { topic: @topic, payload: @payload, timestamp: @timestamp }
      end
    end

    class TickReceived < BaseEvent; end
    class EntryFilled < BaseEvent; end
    class ExitTriggered < BaseEvent; end
    class ExitCompleted < BaseEvent; end
    class MarketOpened < BaseEvent; end
    class MarketClosed < BaseEvent; end
  end
end