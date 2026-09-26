class MatchResult < ApplicationRecord
  belongs_to :match
  belongs_to :reported_by, class_name: "User"
  has_many :match_sets, -> { order(:order) }, dependent: :destroy, inverse_of: :match_result, autosave: true

  accepts_nested_attributes_for :match_sets,
                                allow_destroy: true,
                                reject_if: proc { |attrs|
                                  attrs["team_a_games"].blank? && attrs["team_b_games"].blank?
                                }

  validates :reported_by_id, uniqueness: { scope: :match_id }
  validate :reported_by_is_active_player, unless: :forced_by_admin?
  validate :sets_consistency

  after_create_commit :recalculate_consensus_after_create
  after_update_commit :recalculate_consensus_after_update
  after_destroy_commit :recalculate_consensus_after_destroy,
                     :recalculate_player_stats_after_destroy

  def set_signature
    match_sets.sort_by(&:order).map { |s| "#{s.team_a_games}-#{s.team_b_games}" }.join(",")
  end

  def winner_team
    a_sets = match_sets.count { |s| s.team_a_games > s.team_b_games }
    b_sets = match_sets.count { |s| s.team_b_games > s.team_a_games }

    return nil if a_sets == b_sets

    a_sets > b_sets ? :team_a : :team_b
  end

  private

  def recalculate_consensus_after_create
    recalculate_match_consensus
  end

  def recalculate_consensus_after_update
    recalculate_match_consensus
  end

  def recalculate_consensus_after_destroy
    recalculate_match_consensus
  end

  def recalculate_player_stats_after_destroy
    target = match if match&.persisted?
    target ||= Match.find_by(id: match_id)
    return if target.nil?

    target.active_match_players.includes(:user).each do |mp|
      PlayerStat.recalculate_for(mp.user)
    end
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

  def sets_consistency
    return if match.blank?
    return if forced_by_admin? && match_sets.empty?
    return if match_sets.empty?

    best_of = match.best_of
    sets_needed = (best_of / 2) + 1

    if match_sets.size > best_of
      errors.add(:base, "too many sets (max #{best_of})")
    end

    if match_sets.size < sets_needed
      errors.add(:base, "not enough sets (min #{sets_needed})")
    end

    a_wins = match_sets.count { |s| s.team_a_games > s.team_b_games }
    b_wins = match_sets.count { |s| s.team_b_games > s.team_a_games }

    if a_wins == b_wins
      errors.add(:base, "match cannot end in a tie")
    elsif [ a_wins, b_wins ].max != sets_needed
      errors.add(:base, "winner must have exactly #{sets_needed} sets")
    end
  end
end
