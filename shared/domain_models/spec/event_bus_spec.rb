# frozen_string_literal: true

require "spec_helper"

RSpec.describe DomainModels::EventBus do
  before { described_class.instance.clear }

  it "subscribes and publishes" do
    received = nil
    described_class.instance.subscribe(:test_topic) { |p| received = p }
    described_class.instance.publish(:test_topic, { foo: "bar" })
    expect(received).to eq({ foo: "bar" })
  end

  it "handles multiple subscribers" do
    payloads = []
    described_class.instance.subscribe(:multi) { |p| payloads << "a:#{p}" }
    described_class.instance.subscribe(:multi) { |p| payloads << "b:#{p}" }
    described_class.instance.publish(:multi, "x")
    expect(payloads).to contain_exactly("a:x", "b:x")
  end

  it "survives subscriber errors" do
    payloads = []
    described_class.instance.subscribe(:safe) { |_| raise "boom" }
    described_class.instance.subscribe(:safe) { |p| payloads << p }
    expect { described_class.instance.publish(:safe, "ok") }.not_to raise_error
    expect(payloads).to eq(["ok"])
  end
end