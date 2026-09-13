class User < ApplicationRecord
  include PlayerCategory
  include PhoneValidatable
  include ImageAttachable

  ROLES = %w[admin player club_owner].freeze
  SELF_LEVEL_RANGE = RANGE
  MAX_AVERAGE_LEVEL = BigDecimal("99.9")
  MAX_AVERAGE_STARS = BigDecimal("9.99")

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

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

  validates :name, :phone, :self_level, presence: true
  validates :name, :phone, length: { maximum: 255 }
  validates :phone, uniqueness: true
  validates :self_level, inclusion: { in: SELF_LEVEL_RANGE }
  validates :average_level,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_AVERAGE_LEVEL
            },
            allow_nil: true
  validates :average_stars,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_AVERAGE_STARS
            },
            allow_nil: true

  validates_image_attachment :avatar

  after_create :ensure_player_stat!

  def has_role?(role)
    user_roles.exists?(role: role.to_s)
  end

  def admin?
    has_role?(:admin)
  end

  def player?
    has_role?(:player)
  end

  def club_owner?
    has_role?(:club_owner)
  end

  def category_label
    self.class.category_label(self_level)
  end

  private

  def ensure_player_stat!
    create_player_stat! unless player_stat
  end
end
