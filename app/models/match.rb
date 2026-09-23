class Match < ApplicationRecord
  include PlayerCategory

  belongs_to :court
  belongs_to :creator, class_name: "User"
  belongs_to :time_slot, optional: true

  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players, source: :user
  has_many :match_results, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :messages, dependent: :destroy

  enum :status, { open: 0, full: 1, confirmed: 2, completed: 3, cancelled: 4, reported: 5 }
  enum :roster_mode, { pairs: 0, individual: 1 }, prefix: true

  enum :level_required, {
    open: 0,
    eighth: 8,
    seventh: 7,
    sixth: 6,
    fifth: 5,
    fourth: 4,
    third: 3,
    second: 2,
    first: 1
  }, prefix: true

  validates :date, :duration, presence: true
  MAX_DURATION = 240

  validates :duration,
            numericality: {
              greater_than: 0,
              less_than_or_equal_to: MAX_DURATION,
              only_integer: true
            }

  validate :time_slot_belongs_to_court
  validate :date_matches_time_slot_day
  validate :roster_fits_pairs_mode, if: :will_save_change_to_roster_mode?

  def active_match_players
    match_players.where.not(status: :cancelled)
  end

  def players_for_team(team)
    active_match_players.where(team: team)
  end

  def team_roster_full?(team)
    players_for_team(team).count >= MatchPlayer::PLAYERS_PER_TEAM
  end

  def roster_complete?
    if roster_mode_pairs?
      MatchPlayer.teams.keys.all? { |team| team_roster_full?(team) }
    else
      active_match_players.count >= MatchPlayer::MAX_PLAYERS
    end
  end

  def refresh_roster_status!
    return unless open? || full?

    if roster_complete?
      update!(status: :full) if open?
    else
      update!(status: :open) if full?
    end
  end

  def cancel_if_creator_left_empty_roster!(user)
    return unless user.id == creator_id
    return if active_match_players.exists?

    update!(status: :cancelled)
  end

  def report_result!(reporter:, team_a_score:, team_b_score:, winner_team: nil)
    unless active_match_players.exists?(user_id: reporter.id)
      raise_invalid_result!("Reporter is not an active player")
    end

    existing = match_results.find_by(reported_by_id: reporter.id)
    if existing && !reported?
      existing.errors.add(:base, "You already reported a result")
      raise ActiveRecord::RecordInvalid, existing
    end

    # Destroy and create in one transaction so consensus callbacks see the final set of reports.
    transaction do
      existing&.destroy!
      match_results.create!(
        reported_by: reporter,
        team_a_score: team_a_score,
        team_b_score: team_b_score,
        winner_team: winner_team
      )
    end
  end

  def recalculate_consensus!
    match_results.reset

    if match_results.empty?
      update!(status: :confirmed) if reported?
      return
    end

    if consensus_result
      update!(status: :completed) unless completed?
      apply_player_stats! unless stats_applied_at.present?
    else
      update!(status: :reported) unless reported?
    end
  end

  # One report is provisional consensus. Otherwise a strict majority (> 50%) of identical scores.
  def consensus_result
    reports = match_results.to_a
    return if reports.empty?

    grouped = reports.group_by { |result| [ result.team_a_score, result.team_b_score ] }
    total = reports.size

    if total == 1
      scores = grouped.keys.first
      return { team_a_score: scores[0], team_b_score: scores[1], votes: 1, total: 1 }
    end

    grouped.each do |scores, results|
      next unless results.size > (total / 2.0)

      return { team_a_score: scores[0], team_b_score: scores[1], votes: results.size, total: total }
    end

    nil
  end

  def consensus?
    consensus_result.present?
  end

  def mark_as_played!
    return if completed?

    update!(status: :completed)
  end

  private

  def time_slot_belongs_to_court
    return if time_slot.blank? || time_slot.court_id == court_id

    errors.add(:time_slot, "must belong to the same court")
  end

  def date_matches_time_slot_day
    return if time_slot.blank? || date.blank?
    return if date.wday == time_slot.day_of_week

    errors.add(:time_slot, "day of week must match match date")
  end

  def roster_fits_pairs_mode
    return unless roster_mode_pairs?

    if active_match_players.where(team: nil).exists?
      errors.add(:roster_mode, "cannot switch to pairs: all players must be assigned to a pair")
    end

    MatchPlayer.teams.keys.each do |team|
      next if players_for_team(team).count <= MatchPlayer::PLAYERS_PER_TEAM

      errors.add(:roster_mode, "cannot switch to pairs: #{team.humanize} has more than #{MatchPlayer::PLAYERS_PER_TEAM} players")
    end
  end

  def raise_invalid_result!(message)
    result = MatchResult.new
    result.errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, result
  end

  # Applied once. Later report deletes do not roll stats back (stats_applied_at).
  def apply_player_stats!
    with_lock do
      return if stats_applied_at.present?

      consensus = consensus_result
      return if consensus.blank?

      score_a = consensus[:team_a_score]
      score_b = consensus[:team_b_score]
      return if score_a.nil? || score_b.nil?

      winner = if score_a > score_b
                 "team_a"
      elsif score_b > score_a
                 "team_b"
      end

      active_match_players.includes(user: :player_stat).each do |match_player|
        stat = match_player.user.player_stat
        next unless stat

        if winner.nil?
          stat.current_streak = 0
        elsif match_player.team == winner
          stat.wins += 1
          stat.current_streak += 1
          stat.best_streak = [ stat.best_streak, stat.current_streak ].max
        else
          stat.losses += 1
          stat.current_streak = 0
        end

        total = stat.wins + stat.losses
        stat.win_rate = total > 0 ? (stat.wins.to_f / total * 100).round(2) : 0
        stat.save!
      end

      update_column(:stats_applied_at, Time.current)
    end
  end
end
