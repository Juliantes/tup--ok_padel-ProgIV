module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_user!
  end

  private

  def authenticate_api_user!
    token = bearer_token
    return render_error("token_missing", status: :unauthorized) if token.blank?

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload[:user_id])
    render_error("token_invalid", status: :unauthorized) unless @current_user
  rescue JsonWebToken::ExpiredSignature
    render_error("token_expired", status: :unauthorized)
  rescue JsonWebToken::InvalidToken
    render_error("token_invalid", status: :unauthorized)
  end

  def current_user
    @current_user
  end

  def bearer_token
    header = request.headers["Authorization"]
    return unless header&.start_with?("Bearer ")

    header.split.last
  end
end
