# frozen_string_literal: true

module PhoneValidatable
  extend ActiveSupport::Concern

  PHONE_FORMAT = /\A\+?[\d\s().-]{8,25}\z/
  PHONE_DIGITS_RANGE = (8..15)

  included do
    validates :phone, format: { with: PHONE_FORMAT }
    validate :phone_has_valid_digit_count
  end

  private

  def phone_has_valid_digit_count
    return if phone.blank?

    digit_count = phone.gsub(/\D/, "").length
    return if digit_count.in?(PHONE_DIGITS_RANGE)

    errors.add(:phone, :invalid)
  end
end
