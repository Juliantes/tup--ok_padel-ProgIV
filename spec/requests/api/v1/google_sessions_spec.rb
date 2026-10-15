# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::GoogleSessions", type: :request do
  let(:firebase_claims) do
    {
      "sub" => "firebase-uid-123",
      "email" => "google.user@example.com",
      "email_verified" => true,
      "name" => "Google User"
    }
  end

  before do
    allow(FirebaseIdTokenVerifier).to receive(:verify).and_return(firebase_claims)
  end

  path "/api/v1/oauth/google" do
    post "Exchange Firebase ID token for API JWT" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          id_token: { type: :string }
        },
        required: [ "id_token" ]
      }

      response(200, "returns a token and user data with a valid Firebase ID token") do
        schema "$ref" => "#/components/schemas/LoginResponse"

        let(:body) { { id_token: "valid.firebase.jwt" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["token"]).to be_present
          expect(body_json["user"]["email"]).to eq("google.user@example.com")
          expect(body_json["user"]["roles"]).to include("player")
        end
      end

      response(200, "logs in an existing user without overwriting profile fields") do
        schema "$ref" => "#/components/schemas/LoginResponse"

        let!(:existing) do
          create(:user, :player, email: "google.user@example.com", name: "Existing Name", phone: "1199999999")
        end
        let(:body) { { id_token: "valid.firebase.jwt" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["user"]["id"]).to eq(existing.id)
          expect(body_json["user"]["name"]).to eq("Existing Name")
          expect(body_json["user"]["phone"]).to eq("1199999999")
        end
      end

      response(401, "returns 401 when the Firebase token is invalid") do
        schema "$ref" => "#/components/schemas/Error"

        before do
          allow(FirebaseIdTokenVerifier).to receive(:verify)
            .and_raise(FirebaseIdTokenVerifier::VerificationError, "bad token")
        end

        let(:body) { { id_token: "invalid" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
        end
      end
    end
  end
end
