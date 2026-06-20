class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from ArgumentError, with: :bad_request

  private

  def not_found(e)
    render json: { error: "Not found: #{e.message}" }, status: :not_found
  end

  def bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end

  def current_runtime_config
    @current_runtime_config ||= begin
      config_name = request.headers['X-Runtime-Config'] || 'main'
      Core::RuntimeConfig.find_by!(name: config_name)
    end
  end

  def execution_gateway
    @execution_gateway ||= Execution::Gateway.new(current_runtime_config)
  end

  def mandate
    @mandate ||= Portfolio::Mandate.new(
      max_weight_per_asset: current_runtime_config.try(:max_weight_per_asset) || 0.10,
      min_cash_buffer_pct:  current_runtime_config.try(:min_cash_buffer_pct) || 0.05
    )
  end
end
