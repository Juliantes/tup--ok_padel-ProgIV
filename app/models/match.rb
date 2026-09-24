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

  scope :pending_auto_approval, ->(threshold_hours: 48) {
    cutoff = threshold_hours.hours.ago
    where(status: :reported)
      .where(
        id: MatchResult.group(:match_id).having("MAX(created_at) < ?", cutoff).select(:match_id)
      )
  }

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

  def report_result!(reporter:, sets:)
    if auto_approved_at.present?
      raise_invalid_result!("Match result is finalized")
    end

    unless active_match_players.exists?(user_id: reporter.id)
      raise_invalid_result!("Reporter is not an active player")
    end

    existing = match_results.find_by(reported_by_id: reporter.id)
    if existing && !reported?
      existing.errors.add(:base, "You already reported a result")
      raise ActiveRecord::RecordInvalid, existing
    end

    transaction do
      existing&.destroy!
      result = match_results.new(reported_by: reporter)
      build_match_sets!(result, sets)
      result.save!
      result
    end
  end

  def recalculate_consensus!
    match_results.reset

    if match_results.where(forced_by_admin: true).exists? && completed?
      return
    end

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

  # One report is provisional consensus. Otherwise a strict majority (> 50%) of identical set signatures.
  def consensus_result
    reports = match_results.includes(:match_sets).to_a
    return if reports.empty?

    grouped = reports.group_by(&:set_signature)
    total = reports.size

    if total == 1
      sig = grouped.keys.first
      return { sets: reports.first.match_sets, votes: 1, total: 1, signature: sig }
    end

    grouped.each do |sig, results|
      next unless results.size > (total / 2.0)

      return { sets: results.first.match_sets, votes: results.size, total: total, signature: sig }
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

  def auto_approve_result!
    return if auto_approved_at.present?
    return unless reported?

    grouped = match_results.group_by(&:set_signature)
    return if grouped.empty?

    _signature, results = grouped.max_by do |_sig, rs|
      [ rs.size, -rs.map(&:created_at).min.to_i ]
    end
    winning_result = results.min_by(&:created_at)

    transaction do
      update!(status: :completed, auto_approved_at: Time.current)
      apply_stats_from!(winner_team: winning_result.winner_team) unless stats_applied_at.present?
    end
  end

  def force_result!(admin:, sets:)
    transaction do
      existing = match_results.find_by(reported_by_id: admin.id)
      existing&.destroy!

      result = match_results.new(reported_by: admin, forced_by_admin: true)
      build_match_sets!(result, sets)
      result.save!

      update!(status: :completed)
      apply_stats_from!(winner_team: result.winner_team)
    end
  end

  def apply_stats_from!(winner_team:)
    with_lock do
      return if stats_applied_at.present?

      active_match_players.includes(user: :player_stat).each do |match_player|
        stat = match_player.user.player_stat
        next unless stat

        if winner_team.nil?
          stat.current_streak = 0
        elsif match_player.team == winner_team.to_s
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
    consensus = consensus_result
    return if consensus.blank?

    winner = calculate_winner_from_sets(consensus[:sets])
    apply_stats_from!(winner_team: winner)
  end

  def build_match_sets!(result, sets)
    sets.each_with_index do |set, idx|
      result.match_sets.build(
        order: idx + 1,
        team_a_games: set[:team_a_games],
        team_b_games: set[:team_b_games]
      )
    end
  end

  def calculate_winner_from_sets(sets)
    a_wins = sets.count { |s| s.team_a_games > s.team_b_games }
    b_wins = sets.count { |s| s.team_b_games > s.team_a_games }
    return nil if a_wins == b_wins

    a_wins > b_wins ? "team_a" : "team_b"
  end
end
