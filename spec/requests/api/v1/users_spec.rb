require "swagger_helper"

RSpec.describe "Api::V1::Users", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user, :player) }

  path "/api/v1/profile" do
    get "Profile" do
      tags "Profile"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns the current user profile with a valid token") do
        schema "$ref" => "#/components/schemas/UserResponse"

        let(:Authorization) { auth_headers_for(user)["Authorization"] }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["user"]["id"]).to eq(user.id)
          expect(body["user"]["email"]).to eq(user.email)
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("token_missing")
        end
      end

      response(401, "returns 401 token_invalid with a malformed token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "Bearer invalid" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("token_invalid")
        end
      end

      response(401, "returns 401 token_expired with an expired token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id }, 1.minute.ago)}" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("token_expired")
        end
      end

      response(401, "returns 401 token_missing, token_invalid, or token_expired") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "Bearer #{JsonWebToken.encode(user_id: 0)}" }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("token_invalid")
        end
      end
    end

    patch "Update profile" do
      tags "Profile"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          phone: { type: :string },
          bio: { type: :string },
          self_level: { type: :integer }
        }
      }

      response(200, "updates the current user profile") do
        schema "$ref" => "#/components/schemas/UserResponse"

        let(:Authorization) { auth_headers_for(user)["Authorization"] }
        let(:body) { { name: "Updated Name", bio: "New bio" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["user"]["name"]).to eq("Updated Name")
          expect(body_json["user"]["bio"]).to eq("New bio")
          expect(user.reload.name).to eq("Updated Name")
        end
      end

      response(401, "returns 401 token_missing without a token") do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        let(:Authorization) { "" }
        let(:body) { { name: "Updated Name" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("token_missing")
        end
      end

      response(422, "returns 422 with invalid data") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(user)["Authorization"] }
        let(:body) { { self_level: 99 } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to be_present
        end
      end

      response(200, "ignores mass assignment of email") do
        schema "$ref" => "#/components/schemas/UserResponse"

        let(:Authorization) { auth_headers_for(user)["Authorization"] }
        let(:body) { { email: "hacker@example.com", name: "Still Me" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["user"]["email"]).to eq(user.email)
          expect(body_json["user"]["name"]).to eq("Still Me")
          expect(user.reload.email).not_to eq("hacker@example.com")
        end
      end
    end
  end

  describe "JWT lifetime" do
    it "returns token_expired after 25 hours" do
      token = JsonWebToken.encode(user_id: user.id)

      travel 25.hours do
        get "/api/v1/profile", headers: { "Authorization" => "Bearer #{token}" }, as: :json
      end

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("token_expired")
    end
  end
end
