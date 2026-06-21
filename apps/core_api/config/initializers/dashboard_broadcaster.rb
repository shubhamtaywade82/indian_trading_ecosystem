# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Run the live broadcast background loop unless we are in a test env or rails console/generator task
  if !Rails.env.test? && !defined?(Rails::Console) && (ENV['RUN_BROADCASTER'] == 'true' || $PROGRAM_NAME.include?('puma') || $PROGRAM_NAME.include?('rails'))
    Thread.new do
      Rails.logger.info "[DashboardBroadcaster] Starting periodic Action Cable broadcast loop (3s interval)..."
      
      loop do
        sleep 3.0
        
        # Resolve config name from DB
        config = Core::RuntimeConfig.find_by(name: 'paper_trading') || 
                 Core::RuntimeConfig.find_by(name: 'main') || 
                 Core::RuntimeConfig.first
                 
        if config
          DashboardBroadcaster.broadcast_update!(config)
        end
      rescue => e
        Rails.logger.error "[DashboardBroadcaster] Error in loop: #{e.message}"
      end
    end
  end
end
