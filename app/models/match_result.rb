class MatchResult < ApplicationRecord
  belongs_to :match
  belongs_to :reported_by, class_name: "User"

  enum :winner_team, { team_a: 1, team_b: 2 }, prefix: true

  MAX_SCORE = 99

  validates :team_a_score, :team_b_score,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_SCORE,
              only_integer: true
            },
            allow_nil: true

  validates :reported_by_id, uniqueness: { scope: :match_id }

  validate :reported_by_is_active_player
  validate :scores_and_winner_consistency

  after_create_commit :recalculate_consensus_after_create
  after_destroy_commit :recalculate_consensus_after_destroy

  private

  def recalculate_consensus_after_create
    recalculate_match_consensus
  end

  def recalculate_consensus_after_destroy
    recalculate_match_consensus
  end

  def recalculate_match_consensus
    target = match if match&.persisted?
    target ||= Match.find_by(id: match_id)
    return if target.nil?

    target.recalculate_consensus!
  end

  def reported_by_is_active_player
    return if match.blank? || reported_by.blank?
    return if match.active_match_players.exists?(user_id: reported_by_id)

    errors.add(:reported_by, "must be an active player of the match")
  end

  def scores_and_winner_consistency
    return if team_a_score.blank? || team_b_score.blank? || winner_team.blank?

    expected = if team_a_score > team_b_score
                 "team_a"
    elsif team_b_score > team_a_score
                 "team_b"
    end

    if expected.nil?
      errors.add(:winner_team, "cannot be set when scores are tied")
    elsif winner_team != expected
      errors.add(:winner_team, "does not match scores")
    end
  end
end
