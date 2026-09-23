require "rails_helper"

RSpec.describe "Admin::Matches", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, :individual, status: :confirmed) }
  let(:team_a_wins_2_0) do
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
  end
  let(:team_b_wins_2_0) do
    [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
  end
  let(:team_a_wins_2_1) do
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 4, team_b_games: 6 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  before { sign_in admin }

  describe "GET /admin/matches/:id" do
    it "shows reported results and consensus" do
      player = create(:user, :player)
      create(:match_player, match: match, user: player, team: :team_a, status: :confirmed)
      create(:match_result, match: match, reported_by: player, result_sets: team_a_wins_2_0)

      get admin_match_path(match)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Results")
      expect(response.body).to include("Consensus:")
      expect(response.body).to include("6-4, 6-4")
    end

    it "redirects guests to sign in" do
      sign_out admin

      get admin_match_path(match)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      sign_in create(:user, :player)

      get admin_match_path(match)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/matches/:id/force_result" do
    let!(:player_a) { create(:user, :player) }
    let!(:player_b) { create(:user, :player) }

    before do
      create(:match_player, match: match, user: player_a, team: :team_a, status: :confirmed)
      create(:match_player, match: match, user: player_b, team: :team_b, status: :confirmed)
      player_a.player_stat.update!(wins: 1, losses: 1, current_streak: 1, best_streak: 1, win_rate: 50)
      player_b.player_stat.update!(wins: 1, losses: 1, current_streak: 1, best_streak: 1, win_rate: 50)
    end

    it "creates a forced report, completes the match, and applies stats" do
      create(:match_result, match: match, reported_by: player_a, result_sets: team_a_wins_2_0)
      create(:match_result, match: match, reported_by: player_b, result_sets: team_b_wins_2_0)
      expect(match.reload).to be_reported

      expect {
        post force_result_admin_match_path(match), params: {
          force_result: { sets: team_a_wins_2_1 }
        }
      }.to change { match.match_results.where(forced_by_admin: true).count }.by(1)

      expect(response).to redirect_to(admin_match_path(match))
      expect(match.reload).to be_completed
      expect(player_a.player_stat.reload.wins).to eq(2)
      expect(player_b.player_stat.reload.losses).to eq(2)
    end

    it "redirects guests to sign in" do
      sign_out admin

      post force_result_admin_match_path(match), params: {
        force_result: { sets: team_a_wins_2_0 }
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /admin/matches/:id/mark_played" do
    it "marks the match completed without a result" do
      post mark_played_admin_match_path(match)

      expect(response).to redirect_to(admin_match_path(match))
      expect(match.reload).to be_completed
      expect(match.stats_applied_at).to be_nil
    end
  end
end
