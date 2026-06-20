class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found(e)
    render json: { error: "Not found: #{e.message}" }, status: :not_found
  end

  def bad_request(e)
    render json: { error: e.message }, status: :bad_request
  end

  def current_account
    account_id = request.headers['X-Account-Id'] || params[:account_id]
    @current_account ||= Account.find_by!(id: account_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Account not found' }, status: :unauthorized and return
  end
end
