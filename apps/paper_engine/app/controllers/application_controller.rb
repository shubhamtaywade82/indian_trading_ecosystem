class ApplicationController < ActionController::API
  class UnauthorizedError < StandardError; end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from UnauthorizedError, with: :unauthorized

  private

  def not_found(e)
    render json: { error: "Not found: #{e.message}" }, status: :not_found
  end

  def bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end

  def unauthorized(e)
    render json: { error: e.message }, status: :unauthorized
  end

  def current_account
    account_id = request.headers['X-Account-Id'] || params[:account_id]
    raise UnauthorizedError, 'Account not found' if account_id.blank?
    @current_account ||= Account.find_by(id: account_id) or raise UnauthorizedError, 'Account not found'
  end
end
