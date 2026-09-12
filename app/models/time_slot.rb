class TimeSlot < ApplicationRecord
  belongs_to :court

  has_many :matches, dependent: :nullify

  validates :day_of_week, inclusion: { in: 0..6 }
  validate :end_time_after_start_time

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, "must be after start time")
  end
end
