# frozen_string_literal: true

class ClubScheduleBuilder
  CellState = Data.define(:court_id, :start_time, :time_slot_id, :end_time, :state, :match_id)

  def initialize(club:, date:)
    @club = club
    @date = date.to_date
  end

  def build
    courts = @club.courts.order(:name).to_a
    court_ids = courts.map(&:id)
    day_of_week = @date.wday

    slots = TimeSlot.where(court_id: court_ids, day_of_week: day_of_week).order(:start_time, :court_id).to_a
    slots_by_court_and_time = slots.index_by { |slot| [ slot.court_id, format_time(slot.start_time) ] }

    booked_matches = Match.where(court_id: court_ids, time_slot_id: slots.map(&:id))
                          .where(date: @date.all_day)
                          .where.not(time_slot_id: nil)
                          .index_by(&:time_slot_id)

    start_times = slots.map { |slot| format_time(slot.start_time) }.uniq.sort
    rows = start_times.map do |start_time|
      sample = slots.find { |slot| format_time(slot.start_time) == start_time }
      {
        start_time: start_time,
        end_time: format_time(sample.end_time)
      }
    end

    cells = courts.flat_map do |court|
      start_times.map do |start_time|
        build_cell(court, start_time, slots_by_court_and_time, booked_matches)
      end
    end

    {
      club: @club,
      date: @date,
      courts: courts,
      rows: rows,
      cells: cells
    }
  end

  private

  def build_cell(court, start_time, slots_by_court_and_time, booked_matches)
    slot = slots_by_court_and_time[[ court.id, start_time ]]

    if slot.nil?
      return CellState.new(court_id: court.id, start_time: start_time, time_slot_id: nil,
                           end_time: nil, state: "empty", match_id: nil)
    end

    end_time = format_time(slot.end_time)
    unless court.active? && slot.is_available
      return CellState.new(court_id: court.id, start_time: start_time, time_slot_id: slot.id,
                           end_time: end_time, state: "blocked", match_id: nil)
    end

    booked = booked_matches[slot.id]
    if booked
      return CellState.new(court_id: court.id, start_time: start_time, time_slot_id: slot.id,
                           end_time: end_time, state: "booked", match_id: booked.id)
    end

    CellState.new(court_id: court.id, start_time: start_time, time_slot_id: slot.id,
                  end_time: end_time, state: "available", match_id: nil)
  end

  def format_time(value)
    value.strftime("%H:%M")
  end
end
