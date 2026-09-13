module ApiAuth
  def auth_headers_for(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include ApiAuth, type: :request
end
