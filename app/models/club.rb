class Club < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :courts, dependent: :destroy
end
