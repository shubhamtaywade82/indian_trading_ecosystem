# frozen_string_literal: true

module DomainModels
  class PositionStateMachine
    VALID_STATES = %i[pending active exited cancelled].freeze

    VALID_TRANSITIONS = {
      pending: %i[active cancelled],
      active:  %i[exited cancelled],
      exited:  [],
      cancelled: []
    }.freeze

    def initialize(current_state = :pending)
      @state = current_state.to_sym
      raise ArgumentError, "Invalid state: #{@state}" unless VALID_STATES.include?(@state)
    end

    attr_reader :state

    def can_transition_to?(target_state)
      VALID_TRANSITIONS[@state]&.include?(target_state.to_sym)
    end

    def transition_to(target_state)
      target = target_state.to_sym
      unless can_transition_to?(target)
        raise TransitionError, "Cannot transition from #{@state} to #{target}"
      end

      from_state = @state
      @state = target
      { from: from_state, to: @state }
    end

    def pending?
      @state == :pending
    end

    def active?
      @state == :active
    end

    def exited?
      @state == :exited
    end

    def cancelled?
      @state == :cancelled
    end

    class TransitionError < StandardError; end
  end
end