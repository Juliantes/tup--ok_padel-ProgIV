# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeSlots::BulkReplace do
  let(:court) { create(:court) }

  describe ".build_intervals" do
    it "generates consecutive 90-minute slots from 08:00 to 23:00" do
      intervals = described_class.build_intervals(
        open_time: "08:00",
        close_time: "23:00",
        duration_minutes: 90,
      )

      expect(intervals.length).to eq(10)
      expect(intervals.first.map { |t| t.strftime("%H:%M") }).to eq(%w[08:00 09:30])
      expect(intervals.last.map { |t| t.strftime("%H:%M") }).to eq(%w[21:30 23:00])
    end

    it "drops partial remainder at the end" do
      intervals = described_class.build_intervals(
        open_time: "08:00",
        close_time: "22:00",
        duration_minutes: 90,
      )

      expect(intervals.length).to eq(9)
      expect(intervals.last.map { |t| t.strftime("%H:%M") }).to eq(%w[20:00 21:30])
    end

    it "returns empty when no full slot fits" do
      intervals = described_class.build_intervals(
        open_time: "08:00",
        close_time: "08:30",
        duration_minutes: 90,
      )

      expect(intervals).to be_empty
    end
  end

  describe "#call" do
    let(:params) do
      {
        open_time: "08:00",
        close_time: "23:00",
        duration_minutes: 90,
        day_of_weeks: [ 1, 2 ]
      }
    end

    it "replaces slots on selected days and keeps other days" do
      sunday_slot = create(:time_slot, court: court, day_of_week: 0, start_time: "10:00", end_time: "11:00")
      create(:time_slot, court: court, day_of_week: 1, start_time: "10:00", end_time: "11:30")

      result = described_class.new(court: court, params: params).call

      expect(result).to be_success
      expect(court.time_slots.where(day_of_week: 1).count).to eq(10)
      expect(court.time_slots.where(day_of_week: 2).count).to eq(10)
      expect(court.time_slots.find_by(id: sunday_slot.id)).to be_present
      expect(court.time_slots.where(day_of_week: 1).order(:start_time).first.start_time.strftime("%H:%M")).to eq("08:00")
    end

    it "returns all court slots ordered in the result" do
      create(:time_slot, court: court, day_of_week: 0, start_time: "09:00", end_time: "10:00")

      result = described_class.new(court: court, params: params).call

      expect(result.time_slots.map(&:day_of_week)).to eq(result.time_slots.sort_by { |s| [ s.day_of_week, s.start_time ] }.map(&:day_of_week))
      expect(result.time_slots.count).to eq(20 + 1)
    end

    it "fails when future bookings exist on slots to remove" do
      slot = create(:time_slot, court: court, day_of_week: 1, start_time: "10:00", end_time: "11:30")
      booking_date = Date.current.next_occurring(:monday)
      create(
        :match,
        court: court,
        time_slot: slot,
        date: booking_date.in_time_zone.change(hour: 10),
        status: :confirmed,
        walk_in: true,
      )

      result = described_class.new(court: court, params: params).call

      expect(result).not_to be_success
      expect(result.errors[:base]).to be_present
      expect(court.time_slots.find(slot.id)).to be_present
    end

    it "allows replace when only past bookings exist" do
      slot = create(:time_slot, court: court, day_of_week: 1, start_time: "10:00", end_time: "11:30")
      booking_date = Date.current.prev_occurring(:monday)
      create(
        :match,
        court: court,
        time_slot: slot,
        date: booking_date.in_time_zone.change(hour: 10),
        status: :confirmed,
        walk_in: true,
      )

      result = described_class.new(court: court, params: params).call

      expect(result).to be_success
    end

    it "fails when no slot fits" do
      result = described_class.new(
        court: court,
        params: params.merge(close_time: "08:30"),
      ).call

      expect(result).not_to be_success
      expect(result.errors[:base]).to be_present
    end
  end
end
