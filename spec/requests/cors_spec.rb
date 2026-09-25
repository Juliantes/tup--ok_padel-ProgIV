require "rails_helper"

RSpec.describe "CORS", type: :request do
  describe "preflight OPTIONS" do
    it "returns CORS headers for an allowed origin" do
      options "/api/v1/courts", headers: {
        "Origin" => "http://localhost:3001",
        "Access-Control-Request-Method" => "GET"
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:3001")
      expect(response.headers["Access-Control-Allow-Methods"]).to include("GET")
    end
  end

  describe "simple GET with Origin" do
    it "includes Access-Control-Allow-Origin" do
      get "/api/v1/courts", headers: { "Origin" => "http://localhost:3001" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:3001")
    end
  end

  describe "request without Origin" do
    it "does not add CORS headers" do
      get "/api/v1/courts", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end
end
