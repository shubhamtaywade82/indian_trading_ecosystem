require_relative "lib/dhan_gateway/version"
Gem::Specification.new do |spec|
  spec.name = "dhan_gateway"
  spec.version = DhanGateway::VERSION
  spec.authors = ["Trading Team"]
  spec.summary = "DhanHQ v2 client"
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "domain_models", "~> 0.1"
end
