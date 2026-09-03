class Court < ApplicationRecord
  belongs_to :club

  has_many :time_slots, dependent: :destroy
  has_many :matches, dependent: :restrict_with_error
end
