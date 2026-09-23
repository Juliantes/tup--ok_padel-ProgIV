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
    it { is_expected.to have_many(:match_sets).dependent(:destroy) }
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
      result = create(:match_result)

      expect(result.match.reload).to be_completed
      expect(result.match.consensus_result).to include(votes: 1, total: 1)
    end

    it "recalculates consensus after destroy" do
      match = create(:match, :individual, status: :confirmed)
      first = create(:user, :player)
      second = create(:user, :player)
      create(:match_player, match: match, user: first, team: :team_a)
      create(:match_player, match: match, user: second, team: :team_b)
      create(
        :match_result,
        match: match,
        reported_by: first,
        result_sets: [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
      )
      second_result = create(
        :match_result,
        match: match,
        reported_by: second,
        result_sets: [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
      )
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

  describe "sets consistency" do
    let(:match) { create(:match, best_of: 3) }

    def build_result(sets)
      build(:match_result, match: match, result_sets: sets)
    end

    it "accepts a valid 2-0 match (best_of 3)" do
      expect(build_result([ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 3 } ])).to be_valid
    end

    it "accepts a valid 2-1 match (best_of 3)" do
      expect(
        build_result(
          [
            { team_a_games: 6, team_b_games: 4 },
            { team_a_games: 4, team_b_games: 6 },
            { team_a_games: 6, team_b_games: 4 }
          ]
        )
      ).to be_valid
    end

    it "rejects a single set for best_of 3" do
      result = build_result([ { team_a_games: 6, team_b_games: 4 } ])

      expect(result).not_to be_valid
      expect(result.errors[:base]).to include("not enough sets (min 2)")
    end

    it "rejects 3-0 for best_of 3" do
      result = build_result(
        [
          { team_a_games: 6, team_b_games: 4 },
          { team_a_games: 6, team_b_games: 4 },
          { team_a_games: 6, team_b_games: 4 }
        ]
      )

      expect(result).not_to be_valid
      expect(result.errors[:base]).to include("winner must have exactly 2 sets")
    end

    it "rejects a tied match" do
      result = build_result([ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 4, team_b_games: 6 } ])

      expect(result).not_to be_valid
      expect(result.errors[:base]).to include("match cannot end in a tie")
    end

    it "rejects a winner with only two sets when best_of 5 requires three" do
      match = create(:match, best_of: 5)
      result = build(
        :match_result,
        match: match,
        result_sets: [
          { team_a_games: 6, team_b_games: 4 },
          { team_a_games: 4, team_b_games: 6 },
          { team_a_games: 4, team_b_games: 6 }
        ]
      )

      expect(result).not_to be_valid
      expect(result.errors[:base]).to include("winner must have exactly 3 sets")
    end
  end

  describe "set_signature and winner_team" do
    it "builds a canonical signature" do
      result = create(
        :match_result,
        result_sets: [
          { team_a_games: 6, team_b_games: 4 },
          { team_a_games: 4, team_b_games: 6 },
          { team_a_games: 7, team_b_games: 5 }
        ]
      )

      expect(result.set_signature).to eq("6-4,4-6,7-5")
    end

    it "calculates winner_team from sets" do
      result = build(
        :match_result,
        result_sets: [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 2 } ]
      )

      expect(result.winner_team).to eq(:team_a)
    end
  end

  describe "best_of 5" do
    it "accepts 3-0, 3-1, and 3-2 outcomes" do
      match = create(:match, best_of: 5)
      reporter = create(:user, :player)
      create(:match_player, match: match, user: reporter, team: :team_b, status: :confirmed)

      three_zero = build(:match_result, match: match, reported_by: reporter, result_sets: three_sets_won_by_a)
      three_one = build(
        :match_result,
        match: match,
        reported_by: reporter,
        result_sets: three_sets_won_by_a + [ { team_a_games: 4, team_b_games: 6 } ]
      )
      three_two = build(
        :match_result,
        match: match,
        reported_by: reporter,
        result_sets: three_sets_won_by_a + [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
      )

      expect(three_zero).to be_valid
      expect(three_one).to be_valid
      expect(three_two).to be_valid
    end
  end

  def three_sets_won_by_a
    [
      { team_a_games: 6, team_b_games: 4 },
      { team_a_games: 6, team_b_games: 3 },
      { team_a_games: 6, team_b_games: 2 }
    ]
  end
end
