require_relative "lib/risk_lib/version"
Gem::Specification.new do |spec|
  spec.name = "risk_lib"
  spec.version = RiskLib::VERSION
  spec.authors = ["Trading Team"]
  spec.summary = "Risk and sizing library for Indian trading ecosystem"
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.add_development_dependency "rspec", "~> 3.12"
end
