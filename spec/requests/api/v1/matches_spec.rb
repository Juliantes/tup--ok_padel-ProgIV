require "rails_helper"

RSpec.describe "Api::V1::Matches", type: :request do
  let(:court) { create(:court, status: :active) }
  let(:creator) { create(:user, :player) }
  let(:other_player) { create(:user, :player) }

  let!(:open_match) do
    create(:match, court: court, creator: creator, status: :open, date: 2.days.from_now.change(hour: 10))
  end
  let!(:full_match) do
    create(:match, court: court, creator: creator, status: :full, date: 3.days.from_now.change(hour: 11))
  end
  let!(:confirmed_match) do
    create(:match, court: court, creator: creator, status: :confirmed, date: 4.days.from_now.change(hour: 12))
  end

  describe "GET /api/v1/matches" do
    it "lists only open and full matches without authentication" do
      get "/api/v1/matches", as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["matches"].map { |match| match["id"] }
      expect(ids).to contain_exactly(open_match.id, full_match.id)
      expect(body["meta"]).to include(
        "current_page" => 1,
        "per_page" => 20,
        "total_pages" => 1,
        "total_count" => 2
      )
    end

    it "filters by status, court and date" do
      get "/api/v1/matches",
          params: {
            status: "open",
            court_id: court.id,
            date: open_match.date.to_date.iso8601
          },
          as: :json

      body = JSON.parse(response.body)
      ids = body["matches"].map { |match| match["id"] }
      expect(ids).to eq([ open_match.id ])
    end

    it "paginates results" do
      22.times do |index|
        create(:match, court: court, creator: creator, status: :open, date: (10 + index).days.from_now)
      end

      get "/api/v1/matches", params: { page: 2, per_page: 10 }, as: :json

      body = JSON.parse(response.body)
      expect(body["matches"].size).to eq(10)
      expect(body["meta"]["current_page"]).to eq(2)
      expect(body["meta"]["per_page"]).to eq(10)
      expect(body["meta"]["total_count"]).to eq(24)
    end
  end

  describe "GET /api/v1/matches/:id" do
    it "returns a match with details" do
      create(:match_player, match: open_match, user: creator, team: :team_a)

      get "/api/v1/matches/#{open_match.id}", as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["match"]["id"]).to eq(open_match.id)
      expect(body["match"]["join_policy"]).to eq("auto")
      expect(body["match"]).to have_key("time_slot")
      expect(body["match"]).not_to have_key("match_result")
      expect(body["match"]["match_results"]).to eq([])
      expect(body["match"]["consensus"]).to be_nil
    end

    it "returns 404 for a missing match" do
      get "/api/v1/matches/0", as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Not found")
    end
  end

  describe "POST /api/v1/matches" do
    let(:valid_params) do
      {
        court_id: court.id,
        date: 1.week.from_now.change(hour: 10, min: 0).iso8601,
        duration: 90,
        roster_mode: "pairs",
        level_required: "fifth"
      }
    end

    it "creates a match and enrolls the creator by default" do
      expect do
        post "/api/v1/matches",
             params: valid_params,
             headers: auth_headers_for(creator),
             as: :json
      end.to change(Match, :count).by(1)
         .and change(MatchPlayer, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["match"]["creator"]["id"]).to eq(creator.id)
      expect(body["match"]["match_players"].size).to eq(1)
      expect(body["match"]["match_players"].first["user_id"]).to eq(creator.id)
    end

    it "creates a match without enrolling the creator when auto_join is false" do
      expect do
        post "/api/v1/matches",
             params: valid_params.merge(auto_join: false),
             headers: auth_headers_for(creator),
             as: :json
      end.to change(Match, :count).by(1)

      expect(MatchPlayer.where(match_id: Match.order(:id).last.id)).to be_empty

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["match"]["match_players"]).to be_empty
    end

    it "returns 401 without a token" do
      post "/api/v1/matches", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 with invalid params" do
      post "/api/v1/matches",
           params: valid_params.merge(duration: 0),
           headers: auth_headers_for(creator),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end

  describe "POST /api/v1/matches/:id/join" do
    it "joins a match and returns the updated roster" do
      post "/api/v1/matches/#{open_match.id}/join",
           params: { team: "team_a" },
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      user_ids = body["match"]["match_players"].map { |player| player["user_id"] }
      expect(user_ids).to include(other_player.id)
    end

    it "returns 401 without a token" do
      post "/api/v1/matches/#{open_match.id}/join", params: { team: "team_a" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for a missing match" do
      post "/api/v1/matches/0/join",
           params: { team: "team_a" },
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 in pairs mode without a team" do
      post "/api/v1/matches/#{open_match.id}/join",
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Team is required in pairs mode")
    end

    it "returns 422 when already actively enrolled" do
      create(:match_player, match: open_match, user: other_player, team: :team_b)

      post "/api/v1/matches/#{open_match.id}/join",
           params: { team: "team_b" },
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/matches/:id/leave" do
    let!(:creator_player) do
      create(:match_player, match: open_match, user: creator, team: :team_a)
    end

    it "removes the player from the match" do
      enrolled = create(:match_player, match: open_match, user: other_player, team: :team_b)

      delete "/api/v1/matches/#{open_match.id}/leave",
             headers: auth_headers_for(other_player),
             as: :json

      expect(response).to have_http_status(:ok)
      expect(enrolled.reload.status).to eq("cancelled")
      body = JSON.parse(response.body)
      user_ids = body["match"]["match_players"].map { |player| player["user_id"] }
      expect(user_ids).not_to include(other_player.id)
    end

    it "returns 401 without a token" do
      delete "/api/v1/matches/#{open_match.id}/leave", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 when not enrolled" do
      delete "/api/v1/matches/#{open_match.id}/leave",
             headers: auth_headers_for(other_player),
             as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when the creator tries to leave a confirmed match" do
      create(:match_player, match: confirmed_match, user: creator, team: :team_a)

      delete "/api/v1/matches/#{confirmed_match.id}/leave",
             headers: auth_headers_for(creator),
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Creator cannot leave a confirmed or completed match")
    end

    it "cancels the match when the creator leaves and nobody remains" do
      delete "/api/v1/matches/#{open_match.id}/leave",
             headers: auth_headers_for(creator),
             as: :json

      expect(response).to have_http_status(:ok)
      expect(open_match.reload.status).to eq("cancelled")
    end
  end

  describe "GET /api/v1/me/matches" do
    before do
      create(:match_player, match: open_match, user: creator, team: :team_a)
      create(:match_player, match: full_match, user: other_player, team: :team_a)
    end

    it "returns matches created by or joined by the current user" do
      get "/api/v1/me/matches", headers: auth_headers_for(creator), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["matches"].map { |match| match["id"] }
      expect(ids).to include(open_match.id, full_match.id, confirmed_match.id)
      expect(ids).not_to include(create(:match, court: court, creator: other_player).id)
    end

    it "returns 401 without a token" do
      get "/api/v1/me/matches", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/matches/:id/played" do
    let!(:player) { create(:match_player, match: confirmed_match, user: other_player, team: :team_a) }

    it "marks the match as played for an active player" do
      post "/api/v1/matches/#{confirmed_match.id}/played",
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:ok)
      expect(confirmed_match.reload).to be_completed
      body = JSON.parse(response.body)
      expect(body["match"]["status"]).to eq("completed")
      expect(body["match"]["consensus"]).to be_nil

      post "/api/v1/matches/#{confirmed_match.id}/played",
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without a token" do
      post "/api/v1/matches/#{confirmed_match.id}/played", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 when the user is not an active player" do
      post "/api/v1/matches/#{confirmed_match.id}/played",
           headers: auth_headers_for(creator),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("You are not an active player of this match")
    end

    it "returns 422 when the match is already completed with consensus" do
      create(:match_result, match: confirmed_match, reported_by: other_player, team_a_score: 6, team_b_score: 4, winner_team: :team_a)
      expect(confirmed_match.reload).to be_completed

      post "/api/v1/matches/#{confirmed_match.id}/played",
           headers: auth_headers_for(other_player),
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Match is already completed with a consensus result")
    end
  end
end
