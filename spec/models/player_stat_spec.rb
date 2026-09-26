require "rails_helper"

RSpec.describe PlayerStat, type: :model do
  subject { build(:player_stat) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:win_rate).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:win_rate).is_less_than_or_equal_to(PlayerStat::MAX_WIN_RATE) }

    it "rejects negative wins" do
      stat = build(:player_stat, wins: -1)

      expect(stat).not_to be_valid
      expect(stat.errors[:wins]).to be_present
    end
  end

  describe "#total_matches" do
    it "returns wins plus losses" do
      stat = build(:player_stat, wins: 3, losses: 2)

      expect(stat.total_matches).to eq(5)
    end
  end

  describe ".recalculate_for" do
    let(:team_a_wins_2_0) do
      [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
    end
    let(:team_b_wins_2_0) do
      [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
    end

    def complete_match_for(user:, as_winner:, date:)
      opponent = create(:user, :player)
      match = create(:match, :individual, status: :confirmed, date: date)
      create(:match_player, match: match, user: user, team: :team_a, status: :confirmed)
      create(:match_player, match: match, user: opponent, team: :team_b, status: :confirmed)
      sets = as_winner ? team_a_wins_2_0 : team_b_wins_2_0
      create(:match_result, match: match, reported_by: user, result_sets: sets)
      match.reload
    end

    it "resets stats when the user has no completed consensus matches" do
      user = create(:user, :player)
      user.player_stat.update!(wins: 5, losses: 2, current_streak: 2, best_streak: 4, win_rate: 71.43)

      PlayerStat.recalculate_for(user)

      stat = user.player_stat.reload
      expect(stat.wins).to eq(0)
      expect(stat.losses).to eq(0)
      expect(stat.current_streak).to eq(0)
      expect(stat.best_streak).to eq(0)
      expect(stat.win_rate).to eq(0)
    end

    it "counts a single win" do
      user = create(:user, :player)
      complete_match_for(user: user, as_winner: true, date: 2.days.ago)

      PlayerStat.recalculate_for(user)

      stat = user.player_stat.reload
      expect(stat.wins).to eq(1)
      expect(stat.losses).to eq(0)
      expect(stat.current_streak).to eq(1)
      expect(stat.best_streak).to eq(1)
      expect(stat.win_rate).to eq(100.0)
    end

    it "aggregates wins, losses, and best streak across matches" do
      user = create(:user, :player)
      complete_match_for(user: user, as_winner: true, date: 4.days.ago)
      complete_match_for(user: user, as_winner: true, date: 3.days.ago)
      complete_match_for(user: user, as_winner: true, date: 2.days.ago)
      complete_match_for(user: user, as_winner: false, date: 1.day.ago)

      PlayerStat.recalculate_for(user)

      stat = user.player_stat.reload
      expect(stat.wins).to eq(3)
      expect(stat.losses).to eq(1)
      expect(stat.best_streak).to eq(3)
      expect(stat.current_streak).to eq(0)
      expect(stat.win_rate).to eq(75.0)
    end

    it "resets the current streak after a loss following wins" do
      user = create(:user, :player)
      complete_match_for(user: user, as_winner: true, date: 3.days.ago)
      complete_match_for(user: user, as_winner: false, date: 2.days.ago)
      complete_match_for(user: user, as_winner: true, date: 1.day.ago)

      PlayerStat.recalculate_for(user)

      stat = user.player_stat.reload
      expect(stat.wins).to eq(2)
      expect(stat.losses).to eq(1)
      expect(stat.current_streak).to eq(1)
      expect(stat.best_streak).to eq(1)
    end

    it "updates stats after a match result is destroyed" do
      user = create(:user, :player)
      match = create(:match, :individual, status: :confirmed)
      opponent = create(:user, :player)
      create(:match_player, match: match, user: user, team: :team_a, status: :confirmed)
      create(:match_player, match: match, user: opponent, team: :team_b, status: :confirmed)
      result = create(:match_result, match: match, reported_by: user, result_sets: team_a_wins_2_0)
      expect(user.player_stat.reload.wins).to eq(1)

      result.destroy!

      stat = user.player_stat.reload
      expect(stat.wins).to eq(0)
      expect(stat.losses).to eq(0)
      expect(stat.win_rate).to eq(0)
    end
  end
end
