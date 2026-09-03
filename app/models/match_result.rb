class MatchResult < ApplicationRecord
  belongs_to :match
  belongs_to :reported_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  validate :scores_and_winner_consistency

  private

  def scores_and_winner_consistency
    return if team_a_score.blank? || team_b_score.blank? || winner_team.blank?

    expected_winner = if team_a_score > team_b_score
                        1
                      elsif team_b_score > team_a_score
                        2
                      end

    if expected_winner.nil?
      errors.add(:winner_team, "cannot be set when scores are tied")
    elsif winner_team != expected_winner
      errors.add(:winner_team, "does not match scores")
    end
  end
end
