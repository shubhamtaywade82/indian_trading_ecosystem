# frozen_string_literal: true

require "spec_helper"

RSpec.describe DomainModels::PositionStateMachine do
  describe "transitions" do
    it "starts in pending" do
      sm = described_class.new(:pending)
      expect(sm.state).to eq(:pending)
    end

    it "allows pending -> active" do
      sm = described_class.new(:pending)
      expect(sm.can_transition_to?(:active)).to be true
      result = sm.transition_to(:active)
      expect(result[:to]).to eq(:active)
      expect(sm.state).to eq(:active)
    end

    it "allows pending -> cancelled" do
      sm = described_class.new(:pending)
      expect(sm.can_transition_to?(:cancelled)).to be true
      sm.transition_to(:cancelled)
      expect(sm.state).to eq(:cancelled)
    end

    it "allows active -> exited" do
      sm = described_class.new(:active)
      expect(sm.can_transition_to?(:exited)).to be true
      sm.transition_to(:exited)
      expect(sm.state).to eq(:exited)
    end

    it "forbids active -> pending" do
      sm = described_class.new(:active)
      expect(sm.can_transition_to?(:pending)).to be false
      expect { sm.transition_to(:pending) }.to raise_error(DomainModels::PositionStateMachine::TransitionError)
    end

    it "forbids exited -> anything" do
      sm = described_class.new(:exited)
      expect(sm.can_transition_to?(:active)).to be false
    end
  end
end