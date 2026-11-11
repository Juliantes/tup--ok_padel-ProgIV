require "swagger_helper"

RSpec.describe "Api::V1::Players", type: :request do
  let(:viewer) { create(:user, :player) }
  let!(:target_player) do
    user = create(:user, :player, name: "Ana Jugadora")
    user.player_stat.update!(wins: 5, losses: 3, current_streak: 2, best_streak: 4, win_rate: 62.5)
    user
  end
  let!(:other_player) { create(:user, :player, name: "Bruno Pádel") }
  let!(:club_owner_only) { create(:user, :club_owner) }

  path "/api/v1/players" do
    get "List players" do
      tags "Players"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :q, in: :query, type: :string, required: false,
                description: "Filter by player name"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response(200, "lists players with stats") do
        schema "$ref" => "#/components/schemas/PlayersResponse"

        let(:Authorization) { auth_headers_for(viewer)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["players"].map { |row| row["id"] }
          expect(ids).to include(target_player.id, other_player.id)
          ana = body["players"].find { |row| row["id"] == target_player.id }
          expect(ana).to include(
            "wins" => 5,
            "losses" => 3,
            "played" => 8,
            "current_streak" => 2
          )
          expect(body["meta"]).to include("current_page" => 1, "per_page" => 20)
        end
      end

      response(200, "filters by name query") do
        schema "$ref" => "#/components/schemas/PlayersResponse"

        let(:Authorization) { auth_headers_for(viewer)["Authorization"] }
        let(:q) { "Ana" }

        run_test! do |response|
          body = JSON.parse(response.body)
          names = body["players"].map { |row| row["name"] }
          expect(names).to eq([ "Ana Jugadora" ])
        end
      end

      response(401, "unauthorized without token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }

        run_test!
      end

      response(403, "forbidden without player role") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(club_owner_only)["Authorization"] }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("player role required")
        end
      end
    end
  end

  path "/api/v1/players/{id}" do
    get "Show player" do
      tags "Players"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :integer

      response(200, "returns player detail with reviews") do
        schema "$ref" => "#/components/schemas/PlayerDetailResponse"

        let(:Authorization) { auth_headers_for(viewer)["Authorization"] }
        let(:id) { target_player.id }

        let!(:review) do
          create(
            :review,
            reviewed_user: target_player,
            reviewer: other_player,
            stars: 4,
            comment: "Buen compañero"
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["id"]).to eq(target_player.id)
          expect(body["star_counts"]).to include("4" => 1)
          expect(body["reviews"].length).to eq(1)
          expect(body["reviews"].first).to include(
            "stars" => 4,
            "comment" => "Buen compañero"
          )
          expect(body["reviews"].first["reviewer"]["name"]).to eq("Bruno Pádel")
        end
      end

      response(404, "not found for non-player user") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(viewer)["Authorization"] }
        let(:id) { club_owner_only.id }

        run_test!
      end
    end
  end
end
