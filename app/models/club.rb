class Club < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :courts, dependent: :destroy

  validates :name, :address, :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
