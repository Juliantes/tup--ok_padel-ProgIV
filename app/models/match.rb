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
end
