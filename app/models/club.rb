class Club < ApplicationRecord
  include PhoneValidatable

  CARD_THEMES = [ 0, 1, 2, 3, 4 ].freeze

  belongs_to :owner, class_name: "User"

  has_many :courts, dependent: :destroy

  validates :name, :address, :phone, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, length: { maximum: 255 }
  validates :card_theme, inclusion: { in: CARD_THEMES }
  validates :country, :province, :city, length: { maximum: 255 }, allow_blank: true
  validates :place_id, length: { maximum: 255 }, allow_blank: true
  validate :location_fields_all_or_none
  validate :geocoding_fields_all_or_none

  private

  def location_fields_all_or_none
    values = [ country, province, city ].map { |value| value.to_s.strip }
    present_count = values.count(&:present?)
    return if present_count.zero? || present_count == 3

    errors.add(:base, "country, province, and city must all be present or all blank")
  end

  def geocoding_fields_all_or_none
    values = [ lat, lng, place_id ].map { |value| value.to_s.strip }
    present_count = values.count(&:present?)
    return if present_count.zero? || present_count == 3

    errors.add(:base, "lat, lng, and place_id must all be present or all blank")
  end
end
