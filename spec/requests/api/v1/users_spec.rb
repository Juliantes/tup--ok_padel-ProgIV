require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { create(:user, :player) }

  describe "GET /api/v1/profile" do
    it "returns the current user profile with a valid token" do
      get "/api/v1/profile", headers: auth_headers_for(user), as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["id"]).to eq(user.id)
      expect(body["user"]["email"]).to eq(user.email)
    end

    it "returns 401 without a token" do
      get "/api/v1/profile", as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
    end

    it "returns 401 with an invalid token" do
      get "/api/v1/profile", headers: { "Authorization" => "Bearer invalid" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["error"]).to eq("Unauthorized")
    end
  end

  describe "PATCH /api/v1/profile" do
    it "updates the current user profile" do
      patch "/api/v1/profile",
            params: { name: "Updated Name", bio: "New bio" },
            headers: auth_headers_for(user),
            as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["user"]["name"]).to eq("Updated Name")
      expect(body["user"]["bio"]).to eq("New bio")
      expect(user.reload.name).to eq("Updated Name")
    end

    it "returns 422 with invalid data" do
      patch "/api/v1/profile",
            params: { self_level: 99 },
            headers: auth_headers_for(user),
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to be_present
    end
  end
end
