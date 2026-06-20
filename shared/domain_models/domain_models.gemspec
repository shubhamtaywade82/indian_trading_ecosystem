# frozen_string_literal: true

require_relative "lib/domain_models/version"

Gem::Specification.new do |spec|
  spec.name = "domain_models"
  spec.version = DomainModels::VERSION
  spec.authors = ["Trading Team"]
  spec.summary = "Domain models, events, and state machines for the Indian trading ecosystem"
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.add_dependency "concurrent-ruby", "~> 1.2"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "dry-struct", "~> 1.6"
end