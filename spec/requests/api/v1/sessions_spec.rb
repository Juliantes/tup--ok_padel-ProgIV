require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/login" do
    let(:user) { create(:user, :player, email: "player@example.com", password: "password123") }

    it "returns a token and user data with valid credentials" do
      post "/api/v1/login", params: { email: user.email, password: "password123" }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["id"]).to eq(user.id)
      expect(body["user"]["email"]).to eq(user.email)
      expect(body["user"]).not_to have_key("encrypted_password")
    end

    it "returns 401 with invalid credentials" do
      post "/api/v1/login", params: { email: user.email, password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Invalid credentials")
    end

    it "returns 401 when user does not exist" do
      post "/api/v1/login", params: { email: "missing@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Invalid credentials")
    end
  end
end
