require "rails_helper"

RSpec.describe MatchSet, type: :model do
  subject { build(:match_set) }

  describe "associations" do
    it { is_expected.to belong_to(:match_result) }
  end

  describe "valid set scores" do
    it "accepts 6-0" do
      expect(build(:match_set, team_a_games: 6, team_b_games: 0)).to be_valid
    end

    it "accepts 6-4" do
      expect(build(:match_set, team_a_games: 6, team_b_games: 4)).to be_valid
    end

    it "accepts 7-5" do
      expect(build(:match_set, team_a_games: 7, team_b_games: 5)).to be_valid
    end

    it "accepts 7-6" do
      expect(build(:match_set, team_a_games: 7, team_b_games: 6)).to be_valid
    end

    it "accepts 8-6" do
      expect(build(:match_set, team_a_games: 8, team_b_games: 6)).to be_valid
    end
  end

  describe "invalid set scores" do
    it "rejects 6-5" do
      set = build(:match_set, team_a_games: 6, team_b_games: 5)

      expect(set).not_to be_valid
      expect(set.errors[:base]).to include("invalid set score")
    end

    it "rejects 6-6" do
      set = build(:match_set, team_a_games: 6, team_b_games: 6)

      expect(set).not_to be_valid
      expect(set.errors[:base]).to include("invalid set score")
    end

    it "rejects 5-4" do
      set = build(:match_set, team_a_games: 5, team_b_games: 4)

      expect(set).not_to be_valid
      expect(set.errors[:base]).to include("invalid set score")
    end

    it "rejects 8-7" do
      set = build(:match_set, team_a_games: 8, team_b_games: 7)

      expect(set).not_to be_valid
      expect(set.errors[:base]).to include("invalid set score")
    end
  end
end
