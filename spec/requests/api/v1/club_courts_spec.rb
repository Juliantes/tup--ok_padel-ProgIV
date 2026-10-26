# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::ClubCourts", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }
  let(:club) { create(:club, owner: owner) }
  let(:other_owner) { create(:user, :club_owner) }
  let(:other_club) { create(:club, owner: other_owner) }
  let!(:active_court) { create(:court, club: club, status: :active, name: "Cancha A") }
  let!(:inactive_court) { create(:court, club: club, status: :inactive, name: "Cancha B") }

  path "/api/v1/clubs/{club_id}/courts" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"

    get "List club courts" do
      tags "Club owner"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns all courts for an owned club") do
        schema "$ref" => "#/components/schemas/CourtsResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }

        run_test! do |response|
          ids = JSON.parse(response.body)["courts"].map { |court| court["id"] }
          expect(ids).to contain_exactly(active_court.id, inactive_court.id)
        end
      end

      response(404, "returns 404 for another owner's club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { other_club.id }

        run_test!
      end

      response(403, "returns 403 for a player") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:club_id) { club.id }

        run_test!
      end
    end

    post "Create court" do
      tags "Club owner"
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
        required: %w[name court_type price_per_hour status]
      }

      response(201, "creates a court on an owned club") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) do
          {
            name: "Cancha nueva",
            court_type: "outdoor",
            price_per_hour: 7500,
            description: "Con iluminación",
            status: "active"
          }
        end

        run_test! do |response|
          court_json = JSON.parse(response.body)["court"]
          expect(court_json["name"]).to eq("Cancha nueva")
          expect(court_json["club"]["id"]).to eq(club.id)
        end
      end
    end
  end

  path "/api/v1/clubs/{club_id}/courts/{id}" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :id, in: :path, type: :integer, description: "Court ID"

    patch "Update court" do
      tags "Club owner"
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

      response(200, "updates a court on an owned club") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { active_court.id }
        let(:body) { { status: "maintenance" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["court"]["status"]).to eq("maintenance")
        end
      end

      response(404, "returns 404 when the court belongs to another owner's club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { create(:court, club: other_club).id }
        let(:body) { { name: "Hack" } }

        run_test!
      end
    end

    delete "Delete court" do
      tags "Club owner"
      security [ { bearer_auth: [] } ]

      response(204, "deletes a court without matches") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:id) { create(:court, club: club).id }

        run_test! do
          expect(Court.exists?(id)).to be(false)
        end
      end
    end
  end
end
