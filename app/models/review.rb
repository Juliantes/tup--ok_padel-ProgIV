class Review < ApplicationRecord
  include PlayerCategory

  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewed_user, class_name: "User"
  belongs_to :match

  validates :level_rating, :stars, presence: true
  validates :level_rating, inclusion: { in: RANGE }
  validates :stars, inclusion: { in: 1..5 }
  validate :reviewed_user_is_not_reviewer

  private

  def reviewed_user_is_not_reviewer
    return if reviewer_id.blank? || reviewed_user_id.blank?
    return unless reviewer_id == reviewed_user_id

    errors.add(:reviewed_user, "cannot be the same as reviewer")
  end
end
