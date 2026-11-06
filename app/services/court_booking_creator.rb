# frozen_string_literal: true

class CourtBookingCreator
  def initialize(player:, params:)
    @player = player
    @params = params
  end

  def call
    club = Club.find_by(id: @params[:club_id])
    return failure("Club not found") if club.nil?

    court = club.courts.find_by(id: @params[:court_id])
    return failure("Court not found") if court.nil?

    time_slot = court.time_slots.find_by(id: @params[:time_slot_id])
    return failure("Time slot not found") if time_slot.nil?

    booking_date = parse_date(@params[:date])
    return failure("Invalid date") if booking_date.nil?

    resolver = TimeSlots::ForDate.new(court: court, date: booking_date)
    unless resolver.slots.any? { |slot| slot.id == time_slot.id }
      return failure("Time slot is not available for this date")
    end

    unless court.active? && time_slot.is_available
      return failure("Court or time slot is not available")
    end

    if slot_booked?(time_slot, booking_date)
      return failure("Time slot is already booked for this date")
    end

    starts_at = booking_datetime(booking_date, time_slot)
    if starts_at <= Time.current
      return failure("Cannot book in the past")
    end

    match = Match.new(
      court: court,
      creator: @player,
      time_slot: time_slot,
      date: starts_at,
      duration: slot_duration_minutes(time_slot),
      status: :confirmed,
      join_policy: :manual,
      roster_mode: :pairs,
      level_required: :open,
      walk_in: false,
      player_booking: true
    )

    if match.save
      Result.new(success: true, match: match, record: nil, message: nil)
    else
      Result.new(success: false, match: nil, record: match, message: nil)
    end
  rescue ActiveRecord::RecordNotUnique
    failure("Time slot is already booked for this date")
  end

  Result = Data.define(:success, :match, :record, :message) do
    def success?
      success
    end
  end

  private

  def failure(message)
    Result.new(success: false, match: nil, record: nil, message: message)
  end

  def parse_date(value)
    return nil if value.blank?

    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end

  def booking_datetime(date, time_slot)
    Time.zone.parse("#{date.iso8601} #{time_slot.start_time.strftime('%H:%M')}")
  end

  def slot_duration_minutes(time_slot)
    ((time_slot.end_time - time_slot.start_time) / 60).to_i
  end

  def slot_booked?(time_slot, date)
    Match.where(time_slot_id: time_slot.id)
         .where(date: date.all_day)
         .where.not(status: :cancelled)
         .exists?
  end
end
