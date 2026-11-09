# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::Addresses", type: :request do
  let(:owner) { create(:user, :club_owner) }

  path "/api/v1/addresses/autocomplete" do
    get "Autocomplete addresses" do
      tags "Addresses"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :q, in: :query, type: :string, required: true

      response(200, "returns cached matches") do
        schema "$ref" => "#/components/schemas/AddressAutocompleteResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:q) { "La Plat" }

        before { create(:address, city: "La Plata", formatted: "Av 7, La Plata, Argentina") }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["addresses"].size).to eq(1)
          expect(body["addresses"].first["city"]).to eq("La Plata")
          expect(body["addresses"].first["place_id"]).to be_present
        end
      end

      response(200, "returns empty for short query") do
        schema "$ref" => "#/components/schemas/AddressAutocompleteResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:q) { "ab" }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["addresses"]).to eq([])
        end
      end

      response(401, "returns 401 without a token") do
        let(:Authorization) { nil }
        let(:q) { "La Plata" }

        run_test!
      end
    end
  end
end
