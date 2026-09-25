require "swagger_helper"

RSpec.describe "Api::V1::Courts", type: :request do
  let!(:active_court) { create(:court, status: :active) }
  let!(:inactive_court) { create(:court, status: :inactive) }

  path "/api/v1/courts" do
    get "List courts" do
      tags "Courts"
      produces "application/json"
      security []

      response(200, "lists active courts without authentication") do
        schema "$ref" => "#/components/schemas/CourtsResponse"

        run_test! do |response|
          body = JSON.parse(response.body)
          ids = body["courts"].map { |court| court["id"] }
          expect(ids).to include(active_court.id)
          expect(ids).not_to include(inactive_court.id)
        end
      end
    end
  end

  path "/api/v1/courts/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Court ID"

    get "Show court" do
      tags "Courts"
      produces "application/json"
      security []

      response(200, "returns an active court without authentication") do
        schema "$ref" => "#/components/schemas/CourtResponse"

        let(:id) { active_court.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["court"]["id"]).to eq(active_court.id)
          expect(body["court"]["club"]["name"]).to eq(active_court.club.name)
        end
      end

      response(404, "returns 404 for inactive courts") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { inactive_court.id }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Not found")
        end
      end

      response(404, "returns 404 for missing courts") do
        schema "$ref" => "#/components/schemas/Error"

        let(:id) { 0 }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Not found")
        end
      end
    end
  end
end
