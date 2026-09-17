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
    it {
      is_expected.to validate_numericality_of(:duration)
        .only_integer
        .is_less_than_or_equal_to(Match::MAX_DURATION)
    }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:roster_mode).with_values(pairs: 0, individual: 1).with_prefix(:roster_mode) }
  end

  describe "roster" do
    context "in pairs mode" do
      let(:match) { create(:match, status: :open, roster_mode: :pairs) }

      it "is complete when both pairs have two players" do
        create_list(:match_player, 2, match: match, team: :team_a)
        create_list(:match_player, 2, match: match, team: :team_b)

        expect(match.roster_complete?).to be(true)
        expect(match.team_roster_full?(:team_a)).to be(true)
        expect(match.team_roster_full?(:team_b)).to be(true)
      end

      it "is not complete when a pair is missing players" do
        create(:match_player, match: match, team: :team_a)

        expect(match.roster_complete?).to be(false)
        expect(match.team_roster_full?(:team_a)).to be(false)
      end

      it "does not allow switching from individual to pairs when players have no team" do
        individual_match = create(:match, :individual)
        create(:match_player, :without_team, match: individual_match)

        expect(individual_match.update(roster_mode: :pairs)).to be(false)
        expect(individual_match.errors[:roster_mode]).to be_present
      end
    end

    context "in individual mode" do
      let(:match) { create(:match, :individual, status: :open) }

      it "is complete with four active players regardless of team" do
        create_list(:match_player, 4, match: match, team: :team_a)

        expect(match.roster_complete?).to be(true)
      end

      it "is not complete with fewer than four players" do
        create_list(:match_player, 3, match: match)

        expect(match.roster_complete?).to be(false)
      end

      it "marks the match as full with four individual players" do
        create_list(:match_player, 4, match: match, team: nil)

        expect(match.reload).to be_full
      end
    end
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
