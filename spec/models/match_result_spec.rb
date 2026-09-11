require "rails_helper"

RSpec.describe MatchResult, type: :model do
  subject { build(:match_result) }

  describe "associations" do
    it { is_expected.to belong_to(:match) }
    it { is_expected.to belong_to(:reported_by).class_name("User") }
    it { is_expected.to belong_to(:approved_by).class_name("User").optional }
  end

  describe "score consistency" do
    it "rejects a winner that does not match the scores" do
      result = build(:match_result, team_a_score: 6, team_b_score: 4, winner_team: :team_b)

      expect(result).not_to be_valid
      expect(result.errors[:winner_team]).to include("does not match scores")
    end

    it "rejects a winner when scores are tied" do
      result = build(:match_result, team_a_score: 6, team_b_score: 6, winner_team: :team_a)

      expect(result).not_to be_valid
      expect(result.errors[:winner_team]).to include("cannot be set when scores are tied")
    end

    it "accepts a consistent winner" do
      result = build(:match_result, team_a_score: 6, team_b_score: 4, winner_team: :team_a)

      expect(result).to be_valid
    end
  end
end
