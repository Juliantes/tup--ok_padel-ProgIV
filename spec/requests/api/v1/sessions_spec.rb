require "swagger_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  path "/api/v1/login" do
    post "Login" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security []

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: "player@example.com" },
          password: { type: :string, format: :password }
        },
        required: %w[email password]
      }

      let(:user) { create(:user, :player, email: "player@example.com", password: "password123") }

      response(200, "returns a token and user data with valid credentials") do
        schema "$ref" => "#/components/schemas/LoginResponse"

        let(:body) { { email: user.email, password: "password123" } }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          expect(body_json["token"]).to be_present
          expect(body_json["user"]["id"]).to eq(user.id)
          expect(body_json["user"]["email"]).to eq(user.email)
          expect(body_json["user"]).not_to have_key("encrypted_password")
        end
      end

      response(401, "returns 401 with invalid credentials") do
        schema "$ref" => "#/components/schemas/Error"

        let(:body) { { email: user.email, password: "wrong" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Invalid credentials")
        end
      end

      response(401, "returns 401 when user does not exist") do
        schema "$ref" => "#/components/schemas/Error"

        let(:body) { { email: "missing@example.com", password: "password123" } }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("Invalid credentials")
        end
      end
    end
  end
end
