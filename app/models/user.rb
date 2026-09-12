class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_roles, dependent: :destroy
  has_many :owned_clubs, class_name: "Club", foreign_key: :owner_id, dependent: :restrict_with_error
  has_many :created_matches, class_name: "Match", foreign_key: :creator_id, dependent: :restrict_with_error
  has_many :match_players, dependent: :destroy
  has_many :matches, through: :match_players
  has_one :player_stat, dependent: :destroy

  has_many :written_reviews, class_name: "Review", foreign_key: :reviewer_id, dependent: :destroy
  has_many :received_reviews, class_name: "Review", foreign_key: :reviewed_user_id, dependent: :destroy

  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy
  has_many :received_messages, class_name: "Message", foreign_key: :receiver_id, dependent: :destroy
end
