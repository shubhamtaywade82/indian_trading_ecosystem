module Notification
  class Provider
    def self.notify(message, level: :info)
      raise NotImplementedError, "\#{self.class} must implement notify"
    end
  end
end
