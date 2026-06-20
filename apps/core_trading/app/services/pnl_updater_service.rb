# frozen_string_literal: true

class PnlUpdaterService
  def start
    Rails.logger.info("[PnLUpdater] Started")
  end

  def stop
    Rails.logger.info("[PnLUpdater] Stopped")
  end
end
