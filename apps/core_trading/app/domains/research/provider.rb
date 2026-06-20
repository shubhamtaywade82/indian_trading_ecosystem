module Research
  class Provider
    def self.analyze(instrument)
      raise NotImplementedError, "\#{self.class} must implement analyze"
    end
  end
end
