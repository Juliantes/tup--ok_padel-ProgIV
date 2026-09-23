require "rails_helper"

RSpec.describe MatchResult, type: :model do
  subject { build(:match_result) }

  describe "forced_by_admin" do
    it "defaults to false" do
      result = create(:match_result)

      expect(result.forced_by_admin).to be(false)
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:match) }
    it { is_expected.to belong_to(:reported_by).class_name("User") }
  end

  describe "uniqueness" do
    it "rejects two results from the same reporter on one match" do
      existing = create(:match_result)
      duplicate = build(:match_result, match: existing.match, reported_by: existing.reported_by)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:reported_by_id]).to be_present
    end
  end

  describe "reporter" do
    it "rejects a reporter who is not an active player" do
      result = build(:match_result)
      result.match.match_players.where(user_id: result.reported_by_id).update_all(status: MatchPlayer.statuses[:cancelled])

      expect(result).not_to be_valid
      expect(result.errors[:reported_by]).to include("must be an active player of the match")
    end
  end

  describe "consensus callbacks" do
    it "recalculates consensus after create" do
      result = create(:match_result, team_a_score: 6, team_b_score: 4, winner_team: :team_a)

      expect(result.match.reload).to be_completed
      expect(result.match.consensus_result).to include(votes: 1, total: 1)
    end

    it "recalculates consensus after destroy" do
      match = create(:match, :individual, status: :confirmed)
      first = create(:user, :player)
      second = create(:user, :player)
      create(:match_player, match: match, user: first, team: :team_a)
      create(:match_player, match: match, user: second, team: :team_b)
      create(:match_result, match: match, reported_by: first, team_a_score: 6, team_b_score: 4, winner_team: :team_a)
      second_result = create(:match_result, match: match, reported_by: second, team_a_score: 4, team_b_score: 6, winner_team: :team_b)
      expect(match.reload).to be_reported

      second_result.destroy!

      expect(match.reload).to be_completed
      expect(match.consensus_result).to include(votes: 1, total: 1)
    end

    it "does not raise when the match is destroyed with its reports" do
      result = create(:match_result)

      expect { result.match.destroy! }.not_to raise_error
    end
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

    it "rejects scores above the allowed maximum" do
      result = build(:match_result, team_a_score: 100, team_b_score: 4, winner_team: :team_a)

      expect(result).not_to be_valid
      expect(result.errors[:team_a_score]).to be_present
    end
  end
end
