class JsonWebToken
  class Error < StandardError; end
  class ExpiredSignature < Error; end
  class InvalidToken < Error; end

  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature
    raise ExpiredSignature
  rescue JWT::DecodeError
    raise InvalidToken
  end
end
