class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  validates :user_id, uniqueness: { scope: :match_id }
  validate :match_has_capacity, on: :create

  private

  def match_has_capacity
    return if match.match_players.where.not(id: id).count < 4

    errors.add(:match, "already has 4 players")
  end
end
