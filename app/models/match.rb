class Match < ApplicationRecord
  include PlayerCategory

  belongs_to :court
  belongs_to :creator, class_name: "User"
  belongs_to :time_slot, optional: true

  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players, source: :user
  has_one :match_result, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :messages, dependent: :destroy

  enum :status, { open: 0, full: 1, confirmed: 2, completed: 3, cancelled: 4 }
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
end
