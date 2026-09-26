class MatchPlayer < ApplicationRecord
  PLAYERS_PER_TEAM = 2
  MAX_PLAYERS = PLAYERS_PER_TEAM * 2

  belongs_to :match
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, validate: true
  enum :team, { team_a: 1, team_b: 2 }, prefix: true, validate: { allow_nil: true }

  scope :active, -> { where.not(status: :cancelled) }

  validates :user_id, uniqueness: { scope: :match_id }
  validate :no_active_duplicate_enrollment, on: :create
  validate :match_has_capacity, on: :create
  validate :team_required_in_pairs_mode
  validate :team_has_capacity, if: :should_validate_team_capacity?

  before_validation :set_joined_at, on: :create
  before_save :sync_status_timestamps

  after_commit :refresh_match_roster_status

  def self.enroll(match:, user:, **attributes)
    attributes = attributes.symbolize_keys
    attributes[:status] ||= :confirmed

    record = match.match_players.find_by(user: user)

    if record.nil?
      create!(attributes.merge(match: match, user: user))
    elsif record.cancelled?
      record.assign_attributes(attributes)
      record.save!
      record
    else
      record.errors.add(:user_id, :taken)
      raise ActiveRecord::RecordInvalid, record
    end
  end

  private

  def active_siblings
    match.match_players.active.where.not(id: id)
  end

  def no_active_duplicate_enrollment
    return if match.blank? || user_id.blank?
    return unless match.match_players.active.where(user_id: user_id).where.not(id: id).exists?

    errors.add(:user_id, :taken)
  end

  def should_validate_team_capacity?
    match&.roster_mode_pairs? && (new_record? || will_save_change_to_team?)
  end

  def team_required_in_pairs_mode
    return unless match&.roster_mode_pairs?
    return if team.present?

    errors.add(:team, "must be assigned to a pair")
  end

  def team_has_capacity
    return if team.blank? || match.blank?
    return if active_siblings.where(team: team).count < PLAYERS_PER_TEAM

    errors.add(:team, "already has #{PLAYERS_PER_TEAM} players")
  end

  def match_has_capacity
    return if match.blank?
    return if active_siblings.count < MAX_PLAYERS

    errors.add(:match, "already has #{MAX_PLAYERS} players")
  end

  def set_joined_at
    self.joined_at ||= Time.current
  end

  def sync_status_timestamps
    return unless will_save_change_to_status?

    if cancelled?
      self.cancelled_at = Time.current
    elsif status_was == "cancelled"
      self.cancelled_at = nil
      self.joined_at = Time.current
    end
  end

  def refresh_match_roster_status
    match&.refresh_roster_status!
  end
end
