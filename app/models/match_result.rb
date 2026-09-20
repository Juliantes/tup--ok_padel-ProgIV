class MatchResult < ApplicationRecord
  belongs_to :match
  belongs_to :reported_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  enum :status, { pending: 0, approved: 1, disputed: 2 }
  enum :winner_team, { team_a: 1, team_b: 2 }, prefix: true

  MAX_SCORE = 99

  validates :team_a_score, :team_b_score,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_SCORE,
              only_integer: true
            },
            allow_nil: true

  validate :scores_and_winner_consistency

  private

  def scores_and_winner_consistency
    return if team_a_score.blank? || team_b_score.blank? || winner_team.blank?

    expected_winner = if team_a_score > team_b_score
                        "team_a"
    elsif team_b_score > team_a_score
                        "team_b"
    end

    if expected_winner.nil?
      errors.add(:winner_team, "cannot be set when scores are tied")
    elsif winner_team != expected_winner
      errors.add(:winner_team, "does not match scores")
    end
  end
end
