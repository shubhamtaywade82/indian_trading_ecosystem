# frozen_string_literal: true

module RiskLib
  class RiskPolicy
    def evaluate(position:, current_ltp:, elapsed_seconds: nil)
      decisions = []

      decisions << evaluate_stop_loss(position, current_ltp)
      decisions << evaluate_take_profit(position, current_ltp)
      decisions << evaluate_time_stop(position, elapsed_seconds)
      decisions << evaluate_max_loss(position, current_ltp)

      triggered = decisions.compact.find { |d| d[:trigger] }
      triggered || { trigger: false, reason: nil }
    end

    private

    def evaluate_stop_loss(position, current_ltp)
      sl_price = position.meta.dig("sl_price")
      return nil unless sl_price

      trigger = position.side.to_s.downcase == "buy" ? current_ltp <= sl_price : current_ltp >= sl_price
      { trigger: trigger, reason: "stop_loss", trigger_price: sl_price }
    end

    def evaluate_take_profit(position, current_ltp)
      tp_price = position.meta.dig("tp_price")
      return nil unless tp_price

      trigger = position.side.to_s.downcase == "buy" ? current_ltp >= tp_price : current_ltp <= tp_price
      { trigger: trigger, reason: "take_profit", trigger_price: tp_price }
    end

    def evaluate_time_stop(position, elapsed_seconds)
      max_duration = position.meta.dig("max_hold_seconds")
      return nil unless max_duration && elapsed_seconds

      { trigger: elapsed_seconds >= max_duration, reason: "time_stop" }
    end

    def evaluate_max_loss(position, current_ltp)
      max_loss = position.meta.dig("max_loss_rupees")
      return nil unless max_loss && position.entry_price

      pnl = position.side.to_s.downcase == "buy" ?
        (current_ltp - position.entry_price) * position.quantity :
        (position.entry_price - current_ltp) * position.quantity

      { trigger: pnl <= -max_loss, reason: "max_loss", pnl: pnl }
    end
  end
end