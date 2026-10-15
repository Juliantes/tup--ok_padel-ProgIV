# frozen_string_literal: true

class FirebaseOAuthUserProvisioner
  PLACEHOLDER_PHONE_PREFIX = "+549"

  def self.call(claims)
    new(claims).call
  end

  def initialize(claims)
    @claims = claims
  end

  def call
    email = @claims["email"].to_s.downcase.strip
    user = User.find_by(email: email)
    return user if user

    create_user!(email)
  end

  private

  def create_user!(email)
    sub = @claims["sub"].to_s
    name = @claims["name"].presence || email.split("@").first
    password = Devise.friendly_token(32)

    user = User.new(
      email: email,
      name: name,
      password: password,
      self_level: 3,
      phone: placeholder_phone_for(sub)
    )

    User.transaction do
      save_with_unique_phone!(user, sub)
      user.user_roles.create!(role: "player")
    end

    user
  end

  def save_with_unique_phone!(user, sub)
    attempts = 0
    until user.save
      phone_taken = user.errors.added?(:phone, :taken)
      raise ActiveRecord::RecordInvalid, user unless phone_taken

      attempts += 1
      raise ActiveRecord::RecordInvalid, user if attempts > 10

      user.phone = placeholder_phone_for("#{sub}-#{attempts}")
    end
  end

  def placeholder_phone_for(seed)
    numeric = Digest::SHA256.hexdigest(seed).to_i(16)
    local_digits = (numeric % 100_000_000).to_s.rjust(8, "0")

    "#{PLACEHOLDER_PHONE_PREFIX}#{local_digits}"
  end
end
