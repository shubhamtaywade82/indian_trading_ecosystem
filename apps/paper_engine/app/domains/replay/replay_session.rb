module Replay
  class ReplaySession < ApplicationRecord
    self.table_name = "replay_sessions"
    belongs_to :runtime
  end
end
