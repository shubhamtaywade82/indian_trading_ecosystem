class DashboardChannel < ApplicationCable::Channel
  def subscribed
    stream_from "dashboard_channel"
    
    # Broadcast initial state immediately to the subscriber
    transmit_initial_state
  end

  def unsubscribed
    # Any cleanup
  end

  private

  def transmit_initial_state
    config = Core::RuntimeConfig.find_by(name: 'paper_trading') || Core::RuntimeConfig.find_by(name: 'main') || Core::RuntimeConfig.first
    if config
      gateway = Execution::Gateway.new(config)
      funds = gateway.funds || { available: 1000000.0 }
      positions = gateway.positions || {}
      orders = gateway.orders || []
      
      # Calculate total value
      cash = funds[:available].to_f
      pos_val = positions.is_a?(Hash) ? positions.values.sum { |v| v.is_a?(Hash) ? v[:value].to_f : 0 } : 0
      total_value = cash + pos_val

      transmit({
        type: "initial_state",
        data: {
          runtime_config: {
            name: config.name,
            mode: config.mode,
            market_data_source: config.market_data_source
          },
          funds: funds,
          positions: positions,
          orders: orders,
          total_value: total_value,
          cash: cash,
          position_value: pos_val,
          timestamp: Time.current.iso8601
        }
      })
    else
      transmit({
        type: "error",
        message: "No Runtime Configuration found in database. Please seed or configure."
      })
    end
  rescue => e
    transmit({
      type: "error",
      message: "Failed to load initial state: #{e.message}"
    })
  end
end
