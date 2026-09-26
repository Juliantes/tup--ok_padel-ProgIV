class PlayerStat < ApplicationRecord
  MAX_WIN_RATE = BigDecimal("100")

  belongs_to :user

  validates :wins, :losses, :current_streak, :best_streak,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :win_rate,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_WIN_RATE
            }

  def total_matches
    wins + losses
  end

  def self.recalculate_for(user)
    stat = user.player_stat
    return unless stat

    wins = 0
    losses = 0
    current_streak = 0
    best_streak = 0

    user.matches
        .where(status: :completed)
        .includes(:match_results, :match_players)
        .order(:date)
        .each do |match|
      consensus = match.consensus_result
      next if consensus.blank?

      sets = consensus[:sets]
      a_wins = sets.count { |s| s.team_a_games > s.team_b_games }
      b_wins = sets.count { |s| s.team_b_games > s.team_a_games }
      winner = a_wins > b_wins ? "team_a" : "team_b"

      team = match.match_players.find { |mp| mp.user_id == user.id && !mp.cancelled? }&.team
      next if team.blank?

      if team.to_s == winner
        wins += 1
        current_streak += 1
        best_streak = [ best_streak, current_streak ].max
      else
        losses += 1
        current_streak = 0
      end
    end

    total = wins + losses
    win_rate = total.positive? ? (wins.to_f / total * 100).round(2) : 0

    stat.update!(
      wins: wins,
      losses: losses,
      current_streak: current_streak,
      best_streak: best_streak,
      win_rate: win_rate
    )
  end
end
