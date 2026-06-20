require 'dry-validation'

class OrderValidator < Dry::Validation::Contract
  params do
    required(:instrument_id).filled(:string)
    required(:side).filled(:string, included_in?: %w[buy sell])
    required(:order_type).filled(:string, included_in?: %w[MARKET LIMIT SL SL-M])
    required(:product_type).filled(:string, included_in?: %w[CNC MIS NRML])
    required(:qty).filled(:decimal, gt?: 0)
    optional(:price).maybe(:decimal, gt?: 0)
    optional(:trigger_price).maybe(:decimal, gt?: 0)
  end

  rule(:price, :order_type) do
    if %w[LIMIT SL].include?(values[:order_type]) && values[:price].nil?
      key.failure('must be provided for LIMIT and SL orders')
    end
  end

  rule(:trigger_price, :order_type) do
    if %w[SL SL-M].include?(values[:order_type]) && values[:trigger_price].nil?
      key.failure('must be provided for SL and SL-M orders')
    end
  end

  rule(:qty) do
    # Placeholder for instrument-specific lot size validation
    # Ideally, we look up instrument details here, but for now we enforce integer sizes.
    key.failure('must be a whole number for standard equities') unless value % 1 == 0
  end
end
