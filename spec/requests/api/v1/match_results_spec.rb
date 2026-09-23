require "rails_helper"

RSpec.describe "Api::V1::MatchResults", type: :request do
  let(:court) { create(:court, status: :active) }
  let(:player) { create(:user, :player) }
  let(:other_player) { create(:user, :player) }
  let(:match) { create(:match, :individual, court: court, creator: player, status: :confirmed) }
  let!(:enrollment) { create(:match_player, match: match, user: player, team: :team_a) }

  describe "GET /api/v1/matches/:match_id/match_results" do
    it "returns reports and consensus without authentication" do
      create(:match_result, match: match, reported_by: player, team_a_score: 6, team_b_score: 4, winner_team: :team_a)

      get "/api/v1/matches/#{match.id}/match_results", as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["total"]).to eq(1)
      expect(body["results"].first).to include(
        "team_a_score" => 6,
        "team_b_score" => 4,
        "winner_team" => "team_a"
      )
      expect(body["results"].first["reported_by"]).to include("id" => player.id, "name" => player.name)
      expect(body["consensus"]).to include("team_a_score" => 6, "team_b_score" => 4, "votes" => 1, "total" => 1)
    end

    it "returns 404 for a missing match" do
      get "/api/v1/matches/0/match_results", as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/matches/:match_id/match_results" do
    let(:payload) { { team_a_score: 6, team_b_score: 4, winner_team: "team_a" } }

    it "lets an active player report a result" do
      post "/api/v1/matches/#{match.id}/match_results",
           params: payload,
           headers: auth_headers_for(player),
           as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["results"].size).to eq(1)
      expect(body["consensus"]["votes"]).to eq(1)
      expect(body["match"]["status"]).to eq("completed")
      expect(body["match"]["match_results"].size).to eq(1)
      expect(player.player_stat.reload.wins).to eq(1)
    end

    it "returns 401 without a token" do
      post "/api/v1/matches/#{match.id}/match_results", params: payload, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 when the user is not an active player" do
      post "/api/v1/matches/#{match.id}/match_results",
           params: payload,
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Reporter is not an active player")
    end

    it "returns 422 when the player already reported and the match is not in dispute" do
      post "/api/v1/matches/#{match.id}/match_results",
           params: payload,
           headers: auth_headers_for(player),
           as: :json

      post "/api/v1/matches/#{match.id}/match_results",
           params: payload.merge(team_b_score: 2),
           headers: auth_headers_for(player),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("You already reported a result")
      expect(match.match_results.count).to eq(1)
    end
  end

  describe "DELETE /api/v1/matches/:match_id/match_results/:id" do
    let!(:result) do
      create(:match_result, match: match, reported_by: player, team_a_score: 6, team_b_score: 4, winner_team: :team_a)
    end

    it "lets the reporter delete their own result" do
      delete "/api/v1/matches/#{match.id}/match_results/#{result.id}",
             headers: auth_headers_for(player),
             as: :json

      expect(response).to have_http_status(:ok)
      expect(MatchResult.exists?(result.id)).to be(false)
      body = JSON.parse(response.body)
      expect(body["results"]).to eq([])
      expect(body["match"]).to include("id" => match.id)
    end

    it "returns 403 when deleting someone else's result" do
      create(:match_player, match: match, user: other_player, team: :team_b)

      delete "/api/v1/matches/#{match.id}/match_results/#{result.id}",
             headers: auth_headers_for(other_player),
             as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to eq("You can only delete your own result")
      expect(MatchResult.exists?(result.id)).to be(true)
    end

    it "returns 404 when the result does not exist" do
      delete "/api/v1/matches/#{match.id}/match_results/0",
             headers: auth_headers_for(player),
             as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Not found")
    end
  end
end
