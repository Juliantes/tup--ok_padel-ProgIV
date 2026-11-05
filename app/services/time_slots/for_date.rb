# frozen_string_literal: true

module TimeSlots
  class ForDate
    def initialize(court:, date:)
      @court = court
      @date = date.to_date
    end

    def customized?
      @court.court_day_overrides.exists?(date: @date)
    end

    def slots
      if customized?
        @court.time_slots.for_effective_date(@date).order(:start_time)
      else
        @court.time_slots.weekly_template.where(day_of_week: @date.wday).order(:start_time)
      end
    end

    def self.slots_for_courts(court_ids:, date:)
      date = date.to_date
      return [] if court_ids.empty?

      overrides = CourtDayOverride.where(court_id: court_ids, date: date).pluck(:court_id).to_set
      weekly_court_ids = court_ids - overrides.to_a

      weekly = TimeSlot.where(court_id: weekly_court_ids, effective_on: nil, day_of_week: date.wday)
      override_slots = TimeSlot.where(court_id: overrides.to_a, effective_on: date)

      (weekly.to_a + override_slots.to_a).sort_by { |slot| [ slot.court_id, slot.start_time ] }
    end
  end
end
