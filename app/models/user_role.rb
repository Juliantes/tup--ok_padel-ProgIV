class UserRole < ApplicationRecord
  belongs_to :user

  validates :role, presence: true
end
