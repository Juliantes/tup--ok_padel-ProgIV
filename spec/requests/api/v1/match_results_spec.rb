require "swagger_helper"

RSpec.describe "Api::V1::MatchResults", type: :request do
  let(:court) { create(:court, status: :active) }
  let(:player) { create(:user, :player) }
  let(:other_player) { create(:user, :player) }
  let(:match) { create(:match, :individual, court: court, creator: player, status: :confirmed) }
  let!(:enrollment) { create(:match_player, match: match, user: player, team: :team_a) }
  let(:team_a_wins_2_0) do
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  path "/api/v1/matches/{match_id}/match_results" do
    parameter name: :match_id, in: :path, type: :integer, description: "Match ID"

    get "List match results" do
      tags "Match results"
      produces "application/json"
      security []

      response(200, "returns reports and consensus without authentication") do
        schema "$ref" => "#/components/schemas/MatchResultsIndexResponse"

        let(:match_id) { match.id }

        before { create(:match_result, match: match, reported_by: player, result_sets: team_a_wins_2_0) }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["total"]).to eq(1)
          expect(body["results"].first["sets"]).to eq(
            [
              { "order" => 1, "team_a_games" => 6, "team_b_games" => 4 },
              { "order" => 2, "team_a_games" => 6, "team_b_games" => 4 }
            ]
          )
          expect(body["results"].first).to include("winner_team" => "team_a")
          expect(body["results"].first["reported_by"]).to include("id" => player.id, "name" => player.name)
          expect(body["consensus"]).to include("signature" => "6-4,6-4", "votes" => 1, "total" => 1)
          expect(body["consensus"]["sets"].size).to eq(2)
        end
      end

      response(404, "returns 404 for a missing match") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { 0 }

        run_test!
      end
    end

    post "Report match result" do
      tags "Match results"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          sets: {
            type: :array,
            items: {
              type: :object,
              properties: {
                team_a_games: { type: :integer },
                team_b_games: { type: :integer }
              },
              required: %w[team_a_games team_b_games]
            }
          }
        },
        required: [ "sets" ]
      }

      let(:report_body) { { sets: team_a_wins_2_0 } }

      response(201, "lets an active player report a result") do
        schema "$ref" => "#/components/schemas/MatchResultsMutationResponse"

        let(:match_id) { match.id }
        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:body) { report_body }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["results"].size).to eq(1)
          expect(body_json["results"].first["sets"].size).to eq(2)
          expect(body_json["consensus"]["votes"]).to eq(1)
          expect(body_json["match"]["status"]).to eq("completed")
          expect(body_json["match"]["match_results"].size).to eq(1)
          expect(player.player_stat.reload.wins).to eq(1)
        end
      end

      response(401, "returns 401 without a token") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "" }
        let(:match_id) { match.id }
        let(:body) { report_body }

        run_test!
      end

      response(422, "returns 422 when sets are missing") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { match.id }
        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:body) { {} }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("sets is required")
        end
      end

      response(422, "returns 422 when the user is not an active player") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { match.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }
        let(:body) { report_body }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Reporter is not an active player")
        end
      end

      response(422, "returns 422 when the player already reported and the match is not in dispute") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { match.id }
        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:body) do
          { sets: [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 2 } ] }
        end

        before do
          post "/api/v1/matches/#{match.id}/match_results",
               params: report_body,
               headers: auth_headers_for(player),
               as: :json
        end

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("You already reported a result")
          expect(match.match_results.count).to eq(1)
        end
      end
    end
  end

  path "/api/v1/matches/{match_id}/match_results/{id}" do
    parameter name: :match_id, in: :path, type: :integer, description: "Match ID"
    parameter name: :id, in: :path, type: :integer, description: "Match result ID"

    delete "Delete match result" do
      tags "Match results"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      let!(:result) do
        create(:match_result, match: match, reported_by: player, result_sets: team_a_wins_2_0)
      end

      response(200, "lets the reporter delete their own result") do
        schema "$ref" => "#/components/schemas/MatchResultsMutationResponse"

        let(:match_id) { match.id }
        let(:id) { result.id }
        let(:Authorization) { auth_headers_for(player)["Authorization"] }

        run_test! do |response|
          expect(MatchResult.exists?(result.id)).to be(false)
          body = JSON.parse(response.body)
          expect(body["results"]).to eq([])
          expect(body["match"]).to include("id" => match.id)
        end
      end

      response(401, "returns 401 without a token") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { "" }
        let(:match_id) { match.id }
        let(:id) { result.id }

        run_test!
      end

      response(403, "returns 403 when deleting someone else's result") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { match.id }
        let(:id) { result.id }
        let(:Authorization) { auth_headers_for(other_player)["Authorization"] }

        before { create(:match_player, match: match, user: other_player, team: :team_b) }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("You can only delete your own result")
          expect(MatchResult.exists?(result.id)).to be(true)
        end
      end

      response(404, "returns 404 when the result does not exist") do
        schema "$ref" => "#/components/schemas/Error"

        let(:match_id) { match.id }
        let(:id) { 0 }
        let(:Authorization) { auth_headers_for(player)["Authorization"] }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Not found")
        end
      end
    end
  end
end
