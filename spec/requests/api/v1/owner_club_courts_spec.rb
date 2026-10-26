require "swagger_helper"

RSpec.describe "Api::V1::OwnerClubCourts", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:other_owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }

  let(:club) { create(:club, owner: owner) }
  let(:foreign_club) { create(:club, owner: other_owner) }

  let!(:active_court) { create(:court, club: club, name: "Activa", status: :active) }
  let!(:inactive_court) { create(:court, club: club, name: "Inactiva", status: :inactive) }

  let(:valid_court_body) do
    {
      name: "Cancha nueva",
      court_type: "indoor",
      price_per_hour: 7500,
      description: "Césped",
      status: "active"
    }
  end

  path "/api/v1/clubs/{club_id}/courts" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"

    get "List courts for owned club" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "lists all court statuses for the owner") do
        schema "$ref" => "#/components/schemas/CourtsResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          statuses = body["courts"].map { |court| court["status"] }
          expect(statuses).to include("active", "inactive")
        end
      end

      response(404, "returns 404 for a foreign club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { foreign_club.id }

        run_test!
      end
    end

    post "Create court for owned club" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          court_type: { type: :string, enum: %w[indoor outdoor] },
          price_per_hour: { type: :number },
          description: { type: :string, nullable: true },
          status: { type: :string, enum: %w[active maintenance inactive] }
        },
        required: %w[name court_type price_per_hour]
      }

      response(201, "creates a court") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) { valid_court_body }

        run_test!
      end

      response(422, "returns 422 for invalid price") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) { valid_court_body.merge(price_per_hour: 0) }

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{club_id}/courts/{id}" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :id, in: :path, type: :integer, description: "Court ID"

    get "Show court for owned club" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns a court") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { active_court.id }

        run_test!
      end
    end

    patch "Update court for owned club" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          court_type: { type: :string, enum: %w[indoor outdoor] },
          price_per_hour: { type: :number },
          description: { type: :string, nullable: true },
          status: { type: :string, enum: %w[active maintenance inactive] }
        }
      }

      response(200, "updates a court") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { active_court.id }
        let(:body) { { status: "maintenance" } }

        run_test! do
          expect(active_court.reload.status).to eq("maintenance")
        end
      end
    end

    delete "Delete court for owned club" do
      tags "Owner clubs"
      security [ { bearer_auth: [] } ]

      response(204, "deletes a court without matches") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { create(:court, club: club, name: "Borrable").id }

        run_test!
      end
    end
  end

  describe "owner courts vs public index" do
    it "excludes inactive courts from the public courts index" do
      get "/api/v1/courts", as: :json

      ids = JSON.parse(response.body).fetch("courts").map { |court| court["id"] }
      expect(ids).to include(active_court.id)
      expect(ids).not_to include(inactive_court.id)
    end

    it "returns 403 when a player lists owner courts" do
      get "/api/v1/clubs/#{club.id}/courts",
          headers: auth_headers_for(player),
          as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when deleting a court with matches" do
      create(:match, court: active_court, creator: player)

      delete "/api/v1/clubs/#{club.id}/courts/#{active_court.id}",
             headers: auth_headers_for(owner),
             as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(active_court.reload).to be_persisted
    end
  end
end
