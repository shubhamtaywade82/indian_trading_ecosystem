# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiskLib::RiskPolicy do
  subject { described_class.new }

  # Mock position object
  def make_position(side:, entry_price:, quantity:, meta: {})
    double("position",
      side: side,
      entry_price: entry_price,
      quantity: quantity,
      meta: meta
    )
  end

  describe "#evaluate" do
    it "returns no trigger when no conditions are met" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: {})
      result = subject.evaluate(position: pos, current_ltp: 195, elapsed_seconds: nil)
      expect(result[:trigger]).to be false
    end

    it "triggers stop_loss on buy when price falls to sl_price" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "sl_price" => 190 })
      result = subject.evaluate(position: pos, current_ltp: 188, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("stop_loss")
      expect(result[:trigger_price]).to eq(190)
    end

    it "does not trigger stop_loss on buy when price is above sl_price" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "sl_price" => 190 })
      result = subject.evaluate(position: pos, current_ltp: 195, elapsed_seconds: nil)
      expect(result[:trigger]).to be false
    end

    it "triggers stop_loss on sell when price rises to sl_price" do
      pos = make_position(side: "sell", entry_price: 200, quantity: 100, meta: { "sl_price" => 210 })
      result = subject.evaluate(position: pos, current_ltp: 215, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("stop_loss")
    end

    it "triggers take_profit on buy when price reaches tp_price" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "tp_price" => 220 })
      result = subject.evaluate(position: pos, current_ltp: 225, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("take_profit")
    end

    it "does not trigger take_profit before tp_price is reached" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "tp_price" => 220 })
      result = subject.evaluate(position: pos, current_ltp: 215, elapsed_seconds: nil)
      expect(result[:trigger]).to be false
    end

    it "triggers time_stop when elapsed exceeds max_hold_seconds" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "max_hold_seconds" => 300 })
      result = subject.evaluate(position: pos, current_ltp: 200, elapsed_seconds: 350)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("time_stop")
    end

    it "does not trigger time_stop before max_hold_seconds" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "max_hold_seconds" => 300 })
      result = subject.evaluate(position: pos, current_ltp: 200, elapsed_seconds: 100)
      expect(result[:trigger]).to be false
    end

    it "triggers max_loss when loss exceeds max_loss_rupees on buy" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "max_loss_rupees" => 500 })
      # pnl = (195 - 200) * 100 = -500
      result = subject.evaluate(position: pos, current_ltp: 195, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("max_loss")
      expect(result[:pnl]).to eq(-500)
    end

    it "triggers max_loss when loss exceeds max_loss_rupees on sell" do
      pos = make_position(side: "sell", entry_price: 200, quantity: 100, meta: { "max_loss_rupees" => 500 })
      # pnl = (200 - 205) * 100 = -500
      result = subject.evaluate(position: pos, current_ltp: 205, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      expect(result[:reason]).to eq("max_loss")
    end

    it "returns first triggered decision when multiple conditions met" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "sl_price" => 190, "tp_price" => 220 })
      # Both stop_loss and take_profit conditions could be evaluated
      result = subject.evaluate(position: pos, current_ltp: 188, elapsed_seconds: nil)
      expect(result[:trigger]).to be true
      # stop_loss is evaluated first
      expect(result[:reason]).to eq("stop_loss")
    end

    it "handles nil elapsed_seconds gracefully for time_stop" do
      pos = make_position(side: "buy", entry_price: 200, quantity: 100, meta: { "max_hold_seconds" => 300 })
      result = subject.evaluate(position: pos, current_ltp: 200, elapsed_seconds: nil)
      expect(result[:trigger]).to be false
    end
  end
end