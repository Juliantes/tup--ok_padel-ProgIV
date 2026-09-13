require "rails_helper"

RSpec.describe "Api::V1::Courts", type: :request do
  let!(:active_court) { create(:court, status: :active) }
  let!(:inactive_court) { create(:court, status: :inactive) }

  describe "GET /api/v1/courts" do
    it "lists active courts without authentication" do
      get "/api/v1/courts", as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      ids = body["courts"].map { |court| court["id"] }
      expect(ids).to include(active_court.id)
      expect(ids).not_to include(inactive_court.id)
    end
  end

  describe "GET /api/v1/courts/:id" do
    it "returns an active court without authentication" do
      get "/api/v1/courts/#{active_court.id}", as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["court"]["id"]).to eq(active_court.id)
      expect(body["court"]["club"]["name"]).to eq(active_court.club.name)
    end

    it "returns 404 for inactive courts" do
      get "/api/v1/courts/#{inactive_court.id}", as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Not found")
    end

    it "returns 404 for missing courts" do
      get "/api/v1/courts/0", as: :json

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["error"]).to eq("Not found")
    end
  end
end
