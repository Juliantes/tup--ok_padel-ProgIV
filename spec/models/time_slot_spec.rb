require "rails_helper"

RSpec.describe TimeSlot, type: :model do
  subject { build(:time_slot) }

  describe "associations" do
    it { is_expected.to belong_to(:court) }
    it { is_expected.to have_many(:matches).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:day_of_week).in_range(0..6) }
  end

  describe "time range" do
    it "requires end_time to be after start_time" do
      time_slot = build(:time_slot, start_time: Time.zone.parse("12:00"), end_time: Time.zone.parse("11:00"))

      expect(time_slot).not_to be_valid
      expect(time_slot.errors[:end_time]).to include("must be after start time")
    end
  end

  describe "overlap on the same court and day" do
    let(:court) { create(:court) }

    before do
      create(
        :time_slot,
        court: court,
        day_of_week: 1,
        start_time: Time.zone.parse("10:00"),
        end_time: Time.zone.parse("11:30")
      )
    end

    it "rejects an identical slot" do
      duplicate = build(
        :time_slot,
        court: court,
        day_of_week: 1,
        start_time: Time.zone.parse("10:00"),
        end_time: Time.zone.parse("11:30")
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include(
        I18n.t("activerecord.errors.models.time_slot.attributes.base.overlapping")
      )
    end

    it "rejects a partially overlapping slot" do
      overlapping = build(
        :time_slot,
        court: court,
        day_of_week: 1,
        start_time: Time.zone.parse("11:00"),
        end_time: Time.zone.parse("12:00")
      )

      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include(
        I18n.t("activerecord.errors.models.time_slot.attributes.base.overlapping")
      )
    end

    it "allows a back-to-back slot that ends when the other starts" do
      adjacent = build(
        :time_slot,
        court: court,
        day_of_week: 1,
        start_time: Time.zone.parse("11:30"),
        end_time: Time.zone.parse("13:00")
      )

      expect(adjacent).to be_valid
    end

    it "allows the same hours on another day" do
      other_day = build(
        :time_slot,
        court: court,
        day_of_week: 2,
        start_time: Time.zone.parse("10:00"),
        end_time: Time.zone.parse("11:30")
      )

      expect(other_day).to be_valid
    end

    it "allows the same hours on another court" do
      other_court = build(
        :time_slot,
        court: create(:court),
        day_of_week: 1,
        start_time: Time.zone.parse("10:00"),
        end_time: Time.zone.parse("11:30")
      )

      expect(other_court).to be_valid
    end

    it "allows updating a slot without conflicting with itself" do
      slot = court.time_slots.find_by!(day_of_week: 1, start_time: Time.zone.parse("10:00"))

      slot.is_available = false

      expect(slot).to be_valid
    end
  end
end
