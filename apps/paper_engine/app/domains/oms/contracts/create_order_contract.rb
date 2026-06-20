module OMS
  module Contracts
    class CreateOrderContract < Dry::Validation::Contract
      params do
        required(:symbol).filled(:string)
        required(:side).filled(:string, included_in?: %w[BUY SELL])
        required(:quantity).filled(:integer, gt?: 0)
        required(:order_type).filled(:string, included_in?: %w[MARKET LIMIT SL SLM])
        optional(:price).filled(:decimal, gt?: 0)
        optional(:trigger_price).filled(:decimal, gt?: 0)
        optional(:product_type).filled(:string, included_in?: %w[CNC MIS NRML])
      end

      rule(:price) do
        key.failure('is required for LIMIT orders') if values[:order_type] == 'LIMIT' && value.nil?
      end

      rule(:trigger_price) do
        key.failure('is required for Stop Loss orders') if %w[SL SLM].include?(values[:order_type]) && value.nil?
      end
    end
  end
end
