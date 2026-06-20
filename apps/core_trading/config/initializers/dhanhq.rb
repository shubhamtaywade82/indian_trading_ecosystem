# frozen_string_literal: true

require "dhan_hq"
require "DhanHQ/errors"

# Normalize environment variables to support both conventions
ENV['CLIENT_ID'] ||= ENV['DHAN_CLIENT_ID'] if ENV['DHAN_CLIENT_ID'].present?
ENV['ACCESS_TOKEN'] ||= ENV['DHAN_ACCESS_TOKEN'] if ENV['DHAN_ACCESS_TOKEN'].present?

# Initialize DhanHQ Configuration
DhanHQ.configure_with_env
DhanHQ.ensure_configuration! if DhanHQ.respond_to?(:ensure_configuration!)

DhanHQ.configure do |config|
  config.access_token_provider = lambda do
    Dhan::TokenManager.current_token!
  end

  config.on_token_expired = lambda do |_error|
    Rails.logger.warn "[CORE_TRADING] Token expired — forcing refresh via #{ENV.fetch('DHAN_AUTH_MODE', 'totp')} strategy"
    Dhan::TokenManager.clear_cache! if defined?(Dhan::TokenManager)
    Dhan::TokenManager.refresh!(force: true) if defined?(Dhan::TokenManager)
  end
end

# Ensure HTTP 429 is treated as RateLimitError
if defined?(DhanHQ::Constants::DHAN_ERROR_MAPPING) && DhanHQ::Constants::DHAN_ERROR_MAPPING['429'].nil?
  patched_mapping = DhanHQ::Constants::DHAN_ERROR_MAPPING.merge('429' => DhanHQ::RateLimitError).freeze
  DhanHQ::Constants.send(:remove_const, :DHAN_ERROR_MAPPING)
  DhanHQ::Constants.const_set(:DHAN_ERROR_MAPPING, patched_mapping)
end
