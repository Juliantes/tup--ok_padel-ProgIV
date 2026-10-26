require "swagger_helper"

RSpec.describe "Api::V1::OwnerClubs", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:other_owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }

  let!(:owned_club_a) { create(:club, owner: owner, name: "Alpha Club") }
  let!(:owned_club_b) { create(:club, owner: owner, name: "Beta Club") }
  let!(:foreign_club) { create(:club, owner: other_owner) }

  let(:valid_club_body) do
    {
      name: "Nuevo Club",
      address: "Calle 123",
      phone: "1144556677",
      email: "club@example.com"
    }
  end

  path "/api/v1/clubs" do
    get "List owned clubs" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "lists clubs owned by the current user") do
        schema "$ref" => "#/components/schemas/OwnerClubsResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["clubs"].map { |club| club["id"] }
          expect(ids).to eq([ owned_club_a.id, owned_club_b.id ])
          expect(ids).not_to include(foreign_club.id)
        end
      end

      response(401, "returns 401 without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }

        run_test!
      end

      response(403, "returns 403 for a player without club_owner role") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Forbidden")
        end
      end
    end

    post "Create owned club" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          address: { type: :string },
          phone: { type: :string },
          email: { type: :string, nullable: true }
        },
        required: %w[name address phone]
      }

      response(201, "creates a club for the current user") do
        schema "$ref" => "#/components/schemas/OwnerClubResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:body) { valid_club_body }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          club_id = body_json["club"]["id"]
          record = Club.find(club_id)
          expect(record.owner_id).to eq(owner.id)
        end
      end

      response(422, "returns 422 when required fields are missing") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:body) { { name: "Solo nombre" } }

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Club ID"

    get "Show owned club" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns an owned club") do
        schema "$ref" => "#/components/schemas/OwnerClubResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { owned_club_a.id }

        run_test!
      end

      response(404, "returns 404 for another owner's club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { foreign_club.id }

        run_test!
      end
    end

    patch "Update owned club" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          address: { type: :string },
          phone: { type: :string },
          email: { type: :string, nullable: true }
        }
      }

      response(200, "updates an owned club") do
        schema "$ref" => "#/components/schemas/OwnerClubResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { owned_club_a.id }
        let(:body) { { name: "Alpha Renamed" } }

        run_test! do
          expect(owned_club_a.reload.name).to eq("Alpha Renamed")
        end
      end
    end

    delete "Delete owned club" do
      tags "Owner clubs"
      security [ { bearer_auth: [] } ]

      response(204, "deletes an owned club without courts") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { create(:club, owner: owner, name: "Disposable").id }

        run_test! do
          expect(Club.exists?(id)).to be(false)
        end
      end
    end
  end

  describe "authorization and ownership" do
    it "returns 401 for unauthenticated index" do
      get "/api/v1/clubs", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "ignores owner_id in create params and assigns current user" do
      post "/api/v1/clubs",
           params: valid_club_body.merge(owner_id: other_owner.id),
           headers: auth_headers_for(owner),
           as: :json

      expect(response).to have_http_status(:created)
      club_id = JSON.parse(response.body).fetch("club").fetch("id")
      expect(Club.find(club_id).owner_id).to eq(owner.id)
    end

    it "returns 404 when another owner tries to update a foreign club" do
      patch "/api/v1/clubs/#{foreign_club.id}",
            params: { name: "Hack" },
            headers: auth_headers_for(owner),
            as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when deleting a club whose courts have matches" do
      court = create(:court, club: owned_club_a)
      create(:match, court: court, creator: player)

      delete "/api/v1/clubs/#{owned_club_a.id}",
             headers: auth_headers_for(owner),
             as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(owned_club_a.reload).to be_persisted
    end
  end
end
