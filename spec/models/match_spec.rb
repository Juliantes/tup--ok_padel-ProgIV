require "rails_helper"

RSpec.describe Match, type: :model do
  subject { build(:match) }

  describe "associations" do
    it { is_expected.to belong_to(:court) }
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to belong_to(:time_slot).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).only_integer.is_greater_than(0) }
  end

  describe "custom validations" do
    it "rejects a time slot from another court" do
      court = create(:court)
      other_court = create(:court)
      time_slot = create(:time_slot, court: other_court, day_of_week: 1)
      match = build(:match, court: court, time_slot: time_slot, date: next_monday)

      expect(match).not_to be_valid
      expect(match.errors[:time_slot]).to include("must belong to the same court")
    end

    it "rejects a time slot whose day does not match the match date" do
      court = create(:court)
      time_slot = create(:time_slot, court: court, day_of_week: 2)
      match = build(:match, court: court, time_slot: time_slot, date: next_monday)

      expect(match).not_to be_valid
      expect(match.errors[:time_slot]).to include("day of week must match match date")
    end
  end

  def next_monday
    Date.current.next_occurring(:monday).change(hour: 10)
  end
end
