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
end
