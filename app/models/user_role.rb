class UserRole < ApplicationRecord
  ROLES = User::ROLES

  belongs_to :user

  validates :role, presence: true, inclusion: { in: ROLES }
end
