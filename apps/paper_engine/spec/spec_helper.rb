# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"

# Require Paper services
Dir[Rails.root.join("app/services/paper/*.rb")].each { |f| require f }