class DashboardBroadcaster
  def self.broadcast_update!(config)
    return unless config

    gateway = Execution::Gateway.new(config)
    funds = gateway.funds || { available: 0.0 }
    positions = gateway.positions || {}
    orders = gateway.orders || []
    
    cash = funds[:available].to_f
    pos_val = positions.is_a?(Hash) ? positions.values.sum { |v| v.is_a?(Hash) ? v[:value].to_f : 0 } : 0
    total_value = cash + pos_val

    # Fetch strategies in database if any, or seed default names
    strategies = [
      { name: "EmaXoverMomentum", status: "Active", timeframe: "5m", parameters: "9, 21" }
    ]

    # Fetch signals from strategy engine or display status
    signals = []
    
    ActionCable.server.broadcast("dashboard_channel", {
      type: "update",
      data: {
        runtime_config: {
          name: config.name,
          mode: config.mode,
          market_data_source: config.market_data_source
        },
        funds: funds,
        positions: positions,
        orders: orders,
        strategies: strategies,
        signals: signals,
        total_value: total_value,
        cash: cash,
        position_value: pos_val,
        timestamp: Time.current.iso8601
      }
    })
  rescue => e
    Rails.logger.error("[DashboardBroadcaster] Failed to broadcast update: #{e.message}")
  end
end
