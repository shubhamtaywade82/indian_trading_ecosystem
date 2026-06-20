# frozen_string_literal: true

module DomainModels
  module Commands
    class CommandResult
      attr_reader :success, :payload, :error, :reason

      def initialize(success:, payload: nil, error: nil, reason: nil)
        @success = success
        @payload = payload
        @error = error
        @reason = reason
      end

      def success?
        @success
      end

      def failure?
        !@success
      end

      def self.success(payload: nil)
        new(success: true, payload: payload)
      end

      def self.failure(error:, reason: nil)
        new(success: false, error: error, reason: reason)
      end

      def to_h
        { success: @success, payload: @payload, error: @error, reason: @reason }
      end
    end
  end
end