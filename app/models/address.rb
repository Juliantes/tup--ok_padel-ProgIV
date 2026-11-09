# frozen_string_literal: true

class Address < ApplicationRecord
  validates :formatted, :place_id, presence: true
  validates :place_id, uniqueness: true
  validates :street, :city, :province, :postcode, :country, length: { maximum: 255 }, allow_blank: true
  validates :housenumber, length: { maximum: 64 }, allow_blank: true
  validates :lat, :lng, presence: true

  scope :prefix_search, lambda { |query|
    sanitized = sanitize_sql_like(query.to_s.strip)
    return none if sanitized.blank?

    pattern = "#{sanitized}%"
    where(
      "city LIKE :p OR street LIKE :p OR formatted LIKE :p",
      p: pattern
    ).where(country: "Argentina").limit(5)
  }
end
