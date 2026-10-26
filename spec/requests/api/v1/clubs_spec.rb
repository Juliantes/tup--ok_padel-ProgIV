# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Clubs", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }
  let!(:owned_club) { create(:club, owner: owner, name: "Mi Club") }
  let(:other_owner) { create(:user, :club_owner) }
  let!(:other_club) { create(:club, owner: other_owner) }

  path "/api/v1/clubs" do
    get "List owned clubs" do
      tags "Club owner"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns clubs owned by the current user") do
        schema "$ref" => "#/components/schemas/OwnerClubsResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["clubs"].map { |club| club["id"] }
          expect(ids).to include(owned_club.id)
          expect(ids).not_to include(other_club.id)
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
          expect(JSON.parse(response.body)["error"]).to eq("club owner role required")
        end
      end
    end

    post "Create club" do
      tags "Club owner"
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

      response(201, "creates a club for the current owner") do
        schema "$ref" => "#/components/schemas/OwnerClubResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:body) do
          {
            name: "Nuevo Club",
            address: "Calle 123",
            phone: "1122334455",
            email: "club@example.com"
          }
        end

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["club"]["name"]).to eq("Nuevo Club")
          expect(Club.find(body_json["club"]["id"]).owner_id).to eq(owner.id)
        end
      end

      response(422, "returns validation errors") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:body) { { name: "", address: "", phone: "" } }

        run_test! do |response|
          parsed = JSON.parse(response.body)
          expect(parsed["error"]).to eq("unprocessable_entity")
          expect(parsed["errors"]).to be_present
        end
      end
    end
  end

  path "/api/v1/clubs/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Club ID"

    patch "Update club" do
      tags "Club owner"
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
        let(:id) { owned_club.id }
        let(:body) { { name: "Club Actualizado" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["club"]["name"]).to eq("Club Actualizado")
        end
      end

      response(404, "returns 404 for another owner's club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { other_club.id }
        let(:body) { { name: "Hack" } }

        run_test!
      end
    end

    delete "Delete club" do
      tags "Club owner"
      security [ { bearer_auth: [] } ]

      response(204, "deletes an owned club without courts") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { create(:club, owner: owner).id }

        run_test! do
          expect(Club.exists?(id)).to be(false)
        end
      end

      response(404, "returns 404 for another owner's club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { other_club.id }

        run_test!
      end
    end
  end
end
