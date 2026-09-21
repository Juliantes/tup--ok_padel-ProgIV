class TimeSlot < ApplicationRecord
  DAY_NAMES = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado].freeze

  belongs_to :court

  has_many :matches, dependent: :nullify

  validates :day_of_week, inclusion: { in: 0..6 }

  def self.day_name(day_of_week)
    DAY_NAMES[day_of_week]
  end

  def day_name
    self.class.day_name(day_of_week)
  end
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
