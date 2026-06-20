# frozen_string_literal: true

class FeedHealthService
  def start
    Rails.logger.info("[FeedHealth] Monitoring started")
  end

  def stop
    Rails.logger.info("[FeedHealth] Monitoring stopped")
  end
end
