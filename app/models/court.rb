class Court < ApplicationRecord
  belongs_to :club

  has_many :time_slots, dependent: :destroy
  has_many :matches, dependent: :restrict_with_error

  has_one_attached :image

  enum :court_type, { indoor: 0, outdoor: 1 }
  enum :status, { active: 0, maintenance: 1, inactive: 2 }

  validates :name, :price_per_hour, presence: true
  validates :name, uniqueness: { scope: :club_id }
  validates :price_per_hour, numericality: { greater_than: 0 }
end
