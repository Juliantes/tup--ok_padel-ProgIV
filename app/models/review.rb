class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewed_user, class_name: "User"
  belongs_to :match

  validates :level_rating, :stars, presence: true
  validates :level_rating, :stars, inclusion: { in: 1..5 }
  validate :reviewer_cannot_review_self

  private

  def reviewer_cannot_review_self
    return unless reviewer_id == reviewed_user_id

    errors.add(:reviewed_user, "cannot be the same as reviewer")
  end
end
