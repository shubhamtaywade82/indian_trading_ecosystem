# frozen_string_literal: true

module RuntimeScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :runtime

    def self.runtime(runtime)
      where(runtime: runtime)
    end
  end
end
