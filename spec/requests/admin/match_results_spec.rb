require "rails_helper"

RSpec.describe "Admin::MatchResults", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, :individual, status: :confirmed) }
  let(:player) { create(:user, :player) }
  let!(:match_result) do
    create(:match_player, match: match, user: player, team: :team_a, status: :confirmed)
    create(:match_result, match: match, reported_by: player, team_a_score: 6, team_b_score: 4, winner_team: :team_a)
  end

  before { sign_in admin }

  describe "GET /admin/matches/:match_id/match_results/:id/edit" do
    it "returns success" do
      get edit_admin_match_match_result_path(match, match_result)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(player.name)
    end

    it "redirects guests to sign in" do
      sign_out admin

      get edit_admin_match_match_result_path(match, match_result)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      sign_in create(:user, :player)

      get edit_admin_match_match_result_path(match, match_result)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/matches/:match_id/match_results/:id" do
    it "updates scores" do
      patch admin_match_match_result_path(match, match_result), params: {
        match_result: { team_a_score: 7, team_b_score: 5, winner_team: "team_a" }
      }

      expect(response).to redirect_to(admin_match_path(match))
      expect(match_result.reload).to have_attributes(team_a_score: 7, team_b_score: 5)
    end
  end

  describe "DELETE /admin/matches/:match_id/match_results/:id" do
    it "deletes the report and recalculates consensus" do
      second = create(:user, :player)
      create(:match_player, match: match, user: second, team: :team_b, status: :confirmed)
      create(:match_result, match: match, reported_by: second, team_a_score: 4, team_b_score: 6, winner_team: :team_b)
      expect(match.reload).to be_reported

      expect {
        delete admin_match_match_result_path(match, match_result)
      }.to change(MatchResult, :count).by(-1)

      expect(response).to redirect_to(admin_match_path(match))
      expect(match.reload).to be_completed
    end

    it "returns not found when the result does not belong to the match" do
      other_match = create(:match)
      other_result = create(:match_result, match: other_match)

      delete admin_match_match_result_path(match, other_result)

      expect(response).to have_http_status(:not_found)
    end
  end
end
