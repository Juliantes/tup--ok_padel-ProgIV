require "swagger_helper"

RSpec.describe "Api::V1::Matches", type: :request do
  include ActiveSupport::Testing::TimeHelpers

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

  let(:valid_create_body) do
    {
      court_id: court.id,
      date: 1.week.from_now.change(hour: 10, min: 0).iso8601,
      duration: 90,
      roster_mode: "pairs",
      level_required: "fifth"
    }
  end

  path "/api/v1/matches" do
    get "List matches" do
      tags "Matches"
      produces "application/json"
      security []

      parameter name: :status, in: :query, type: :string, required: false,
                description: "Filter by match status (e.g. open, full)"
      parameter name: :court_id, in: :query, type: :integer, required: false
      parameter name: :date, in: :query, type: :string, format: :date, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response(200, "lists only open and full matches without authentication") do
        schema "$ref" => "#/components/schemas/MatchesResponse"

        run_test! do |response|
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
      end

      response(200, "filters by status, court and date") do
        schema "$ref" => "#/components/schemas/MatchesResponse"

        let(:status) { "open" }
        let(:court_id) { court.id }
        let(:date) { open_match.date.to_date.iso8601 }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["matches"].map { |match| match["id"] }
          expect(ids).to eq([ open_match.id ])
        end
      end

      response(200, "paginates results") do
        schema "$ref" => "#/components/schemas/MatchesResponse"

        let(:page) { 2 }
        let(:per_page) { 10 }

        before do
          22.times do |index|
            create(:match, court: court, creator: creator, status: :open, date: (10 + index).days.from_now)
          end
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["matches"].size).to eq(10)
          expect(body["meta"]["current_page"]).to eq(2)
          expect(body["meta"]["per_page"]).to eq(10)
          expect(body["meta"]["total_count"]).to eq(24)
        end
      end

      response(200, "caps per_page at 50") do
        schema "$ref" => "#/components/schemas/MatchesResponse"

        let(:per_page) { 100 }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["meta"]["per_page"]).to eq(50)
        end
      end

      response(400, "invalid status filter") do
        schema "$ref" => "#/components/schemas/Error"

        let(:status) { "not-a-status" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("invalid status")
        end
      end

      response(400, "invalid date filter") do
        schema "$ref" => "#/components/schemas/Error"

        let(:date) { "31/12/2025" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("invalid date format")
        end
      end

      response(400, "invalid court_id filter") do
        schema "$ref" => "#/components/schemas/Error"

        let(:court_id) { "abc" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("invalid court_id")
        end
      end

      response(400, "invalid page filter") do
        schema "$ref" => "#/components/schemas/Error"

        let(:page) { "abc" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("invalid page")
        end
      end

      response(400, "invalid per_page filter") do
        schema "$ref" => "#/components/schemas/Error"

        let(:per_page) { "abc" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("invalid per_page")
        end
      end
    end

    post "Create match" do
      tags "Matches"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          court_id: { type: :integer },
          time_slot_id: { type: :integer, nullable: true },
          date: { type: :string, format: "date-time" },
          duration: { type: :integer },
          roster_mode: { type: :string, enum: %w[pairs individual] },
          level_required: { type: :string },
          auto_join: { type: :boolean },
          join_policy: { type: :string, enum: %w[auto manual auto_by_level] }
        },
        required: %w[court_id date duration roster_mode level_required]
      }

      response(201, "creates a match and enrolls the creator by default") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }
        let(:body) { valid_create_body }

        it "creates a match" do |example|
          expect {
            submit_request(example.metadata)
          }.to change(Match, :count).by(1)
             .and change(MatchPlayer, :count).by(1)

          assert_response_matches_metadata(example.metadata)
          body_json = JSON.parse(response.body)
          expect(body_json["match"]["creator"]["id"]).to eq(creator.id)
          expect(body_json["match"]["join_policy"]).to eq("auto")
          expect(body_json["match"]["match_players"].size).to eq(1)
          player = body_json["match"]["match_players"].first
          expect(player["user_id"]).to eq(creator.id)
          expect(player["user"]).to eq("id" => creator.id, "name" => creator.name)
        end
      end

      response(201, "creates a match with join_policy manual") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }
        let(:body) { valid_create_body.merge(join_policy: "manual", auto_join: false) }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["match"]["join_policy"]).to eq("manual")
        end
      end

      response(201, "creates a match with join_policy auto_by_level") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }
        let(:body) { valid_create_body.merge(join_policy: "auto_by_level", auto_join: false) }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["match"]["join_policy"]).to eq("auto_by_level")
        end
      end

      response(201, "creates a match without enrolling the creator when auto_join is false") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }
        let(:body) { valid_create_body.merge(auto_join: false) }

        it "does not enroll creator" do |example|
          expect {
            submit_request(example.metadata)
          }.to change(Match, :count).by(1)

          assert_response_matches_metadata(example.metadata)
          expect(MatchPlayer.where(match_id: Match.order(:id).last.id)).to be_empty
          body_json = JSON.parse(response.body)
          expect(body_json["match"]["match_players"]).to be_empty
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }
        let(:body) { valid_create_body }

        run_test!
      end

      response(422, "returns 422 with invalid params") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }
        let(:body) { valid_create_body.merge(duration: 0) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["error"]).to eq("unprocessable_entity")
          expect(body["errors"]["duration"]).to be_present
        end
      end
    end

    it "returns 422 for invalid join_policy" do
      post "/api/v1/matches",
           params: valid_create_body.merge(join_policy: "nope"),
           headers: auth_headers_for(creator),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]["join_policy"]).to be_present
    end

    it "returns 422 for invalid roster_mode" do
      post "/api/v1/matches",
           params: valid_create_body.merge(roster_mode: "nope"),
           headers: auth_headers_for(creator),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]["roster_mode"]).to be_present
    end

    it "returns 422 for invalid level_required" do
      post "/api/v1/matches",
           params: valid_create_body.merge(level_required: "nope"),
           headers: auth_headers_for(creator),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]["level_required"]).to be_present
    end
  end

  path "/api/v1/matches/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Match ID"

    get "Show match" do
      tags "Matches"
      produces "application/json"
      security []

      response(200, "returns a match with details") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:id) { open_match.id }

        before { create(:match_player, match: open_match, user: creator, team: :team_a) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["match"]["id"]).to eq(open_match.id)
          expect(body["match"]["join_policy"]).to eq("auto")
          expect(body["match"]).to have_key("time_slot")
          expect(body["match"]).not_to have_key("match_result")
          expect(body["match"]["match_results"]).to eq([])
          expect(body["match"]["consensus"]).to be_nil
        end
      end

      response(404, "returns 404 for a missing match") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { 0 }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Not found")
        end
      end
    end
  end

  path "/api/v1/matches/{id}/join" do
    parameter name: :id, in: :path, type: :integer, description: "Match ID"

    post "Join match" do
      tags "Matches"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          team: { type: :string, enum: %w[team_a team_b] }
        }
      }

      response(200, "joins a match and returns the updated roster") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let(:body) { { team: "team_a" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          user_ids = body_json["match"]["match_players"].map { |player| player["user_id"] }
          expect(user_ids).to include(other_player.id)
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }
        let(:id) { open_match.id }
        let(:body) { { team: "team_a" } }

        run_test!
      end

      response(404, "returns 404 for a missing match") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { 0 }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let(:body) { { team: "team_a" } }

        run_test!
      end

      response(422, "returns 422 in pairs mode without a team") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let(:body) { {} }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Team is required in pairs mode")
        end
      end

      response(422, "returns 422 when already actively enrolled") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let(:body) { { team: "team_b" } }

        before { create(:match_player, match: open_match, user: other_player, team: :team_b) }

        run_test!
      end
    end
  end

  path "/api/v1/matches/{id}/leave" do
    parameter name: :id, in: :path, type: :integer, description: "Match ID"

    delete "Leave match" do
      tags "Matches"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      let!(:creator_player) do
        create(:match_player, match: open_match, user: creator, team: :team_a)
      end

      response(200, "removes the player from the match") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let!(:enrolled) { create(:match_player, match: open_match, user: other_player, team: :team_b) }

        run_test! do |response|
          expect(enrolled.reload.status).to eq("cancelled")
          body = JSON.parse(response.body)
          user_ids = body["match"]["match_players"].map { |player| player["user_id"] }
          expect(user_ids).not_to include(other_player.id)
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }
        let(:id) { open_match.id }

        run_test!
      end

      response(404, "returns 404 when not enrolled") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }

        run_test!
      end

      response(422, "returns 422 when the creator tries to leave a confirmed match") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { confirmed_match.id }
        let(:Authorization) { auth_headers_for(creator)["Authorization"] }

        before { create(:match_player, match: confirmed_match, user: creator, team: :team_a) }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Creator cannot leave a confirmed or completed match")
        end
      end

      response(200, "cancels the match when the creator leaves and nobody remains") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:id) { open_match.id }
        let(:Authorization) { auth_headers_for(creator)["Authorization"] }

        run_test! do
          expect(open_match.reload.status).to eq("cancelled")
        end
      end
    end
  end

  path "/api/v1/me/matches" do
    get "My matches" do
      tags "Matches"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      before do
        create(:match_player, match: open_match, user: creator, team: :team_a)
        create(:match_player, match: full_match, user: other_player, team: :team_a)
      end

      response(200, "returns matches created by or joined by the current user") do
        schema type: :object,
               properties: {
                 matches: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/Match" }
                 }
               },
               required: [ "matches" ]

        let(:Authorization) { auth_headers_for(creator)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["matches"].map { |match| match["id"] }
          expect(ids).to include(open_match.id, full_match.id, confirmed_match.id)
          expect(ids).not_to include(create(:match, court: court, creator: other_player).id)
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }

        run_test!
      end
    end
  end

  path "/api/v1/matches/{id}/played" do
    parameter name: :id, in: :path, type: :integer, description: "Match ID"

    post "Mark match as played" do
      tags "Matches"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      let!(:player) { create(:match_player, match: confirmed_match, user: other_player, team: :team_a) }

      response(200, "marks the match as played for an active player") do
        schema "$ref" => "#/components/schemas/MatchResponse"

        let(:id) { confirmed_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }

        run_test! do |response|
          expect(confirmed_match.reload).to be_completed
          body = JSON.parse(response.body)
          expect(body["match"]["status"]).to eq("completed")
          expect(body["match"]["consensus"]).to be_nil

          post "/api/v1/matches/#{confirmed_match.id}/played",
               headers: auth_headers_for(other_player),
               as: :json

          expect(response).to have_http_status(:ok)
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }
        let(:id) { confirmed_match.id }

        run_test!
      end

      response(422, "returns 422 when the user is not an active player") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { confirmed_match.id }
        let(:Authorization) { auth_headers_for(creator)["Authorization"] }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("You are not an active player of this match")
        end
      end

      response(422, "returns 422 when the match is already completed with consensus") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { confirmed_match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }

        before do
          create(
            :match_result,
            match: confirmed_match,
            reported_by: other_player,
            result_sets: [
              { team_a_games: 6, team_b_games: 4 },
              { team_a_games: 6, team_b_games: 4 }
            ]
          )
          expect(confirmed_match.reload).to be_completed
        end

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Match is already completed with a consensus result")
        end
      end
    end
  end

  describe "time cutoffs" do
    def timed_match(start_at, **overrides)
      time_slot = create(
        :time_slot,
        court: court,
        day_of_week: start_at.wday,
        start_time: start_at,
        end_time: start_at + 90.minutes
      )
      create(
        :match,
        court: court,
        creator: creator,
        status: :open,
        roster_mode: :pairs,
        time_slot: time_slot,
        date: start_at,
        **overrides
      )
    end

    context "when less than 1 hour before start" do
      let(:start_at) { 3.hours.from_now.change(sec: 0) }
      let(:match) { timed_match(start_at) }

      before { create(:match_player, match: match, user: creator, team: :team_a) }

      it "returns 422 on join" do
        travel_to start_at - 30.minutes do
          post "/api/v1/matches/#{match.id}/join",
               params: { team: "team_b" },
               headers: auth_headers_for(other_player),
               as: :json
        end

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to eq("too late to join")
      end
    end

    context "when less than 2 hours before start" do
      let(:start_at) { 4.hours.from_now.change(sec: 0) }
      let(:match) { timed_match(start_at) }
      let!(:enrolled) { create(:match_player, match: match, user: other_player, team: :team_b) }

      before { create(:match_player, match: match, user: creator, team: :team_a) }

      it "returns 422 on leave" do
        travel_to start_at - 90.minutes do
          delete "/api/v1/matches/#{match.id}/leave",
                 headers: auth_headers_for(other_player),
                 as: :json
        end

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to eq("too late to leave")
      end
    end

    context "when more than 24 hours before start" do
      let(:start_at) { 2.days.from_now.change(sec: 0) }
      let(:match) { timed_match(start_at, status: :confirmed) }

      before { create(:match_player, match: match, user: other_player, team: :team_a) }

      it "returns 422 on played" do
        post "/api/v1/matches/#{match.id}/played",
             headers: auth_headers_for(other_player),
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to eq("too early to mark as played")
      end
    end
  end
end
