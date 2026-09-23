class MatchSet < ApplicationRecord
  belongs_to :match_result, inverse_of: :match_sets

  validates :order, presence: true, inclusion: { in: 1..5 }
  validates :order, uniqueness: { scope: :match_result_id }
  validates :team_a_games, :team_b_games,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 99,
              only_integer: true
            }

  validate :valid_set_score

  private

  def valid_set_score
    return if team_a_games.blank? || team_b_games.blank?

    winner = [ team_a_games, team_b_games ].max
    loser = [ team_a_games, team_b_games ].min

    return if winner == 6 && loser <= 4
    return if winner == 7 && loser == 5
    return if winner == 7 && loser == 6
    return if winner >= 8 && (winner - loser) == 2 && loser >= 6

    errors.add(:base, "invalid set score")
  end
end
