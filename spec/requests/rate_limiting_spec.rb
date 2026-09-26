require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    Rack::Attack.cache.store = memory_store
    memory_store.clear
  end

  after do
    Rack::Attack.cache.store = Rails.cache
  end

  describe "POST /api/v1/login" do
    let(:login_params) { { email: "missing@example.com", password: "wrong" } }

    it "returns 429 on the 6th request within a minute" do
      5.times do
        post "/api/v1/login", params: login_params, as: :json
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post "/api/v1/login", params: login_params, as: :json
      expect(response).to have_http_status(:too_many_requests)
    end

    it "includes Retry-After on 429" do
      6.times { post "/api/v1/login", params: login_params, as: :json }

      expect(response.headers["Retry-After"]).to be_present
    end

    it "returns JSON error body on 429" do
      6.times { post "/api/v1/login", params: login_params, as: :json }

      body = JSON.parse(response.body)
      expect(body["error"]).to eq("Too many requests. Please retry later.")
    end
  end

  describe "POST /api/v1/matches without a token" do
    it "returns 429 on the 21st request within a minute" do
      20.times do
        post "/api/v1/matches", params: {}, as: :json
        expect(response).not_to have_http_status(:too_many_requests)
      end

      post "/api/v1/matches", params: {}, as: :json
      expect(response).to have_http_status(:too_many_requests)
    end

    it "does not apply write/ip when an Authorization header is present" do
      21.times do
        post "/api/v1/matches",
          params: {},
          headers: { "Authorization" => "Bearer invalid" },
          as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /up" do
    it "is not throttled" do
      100.times do
        get "/up"
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "OPTIONS /api/v1/courts" do
    it "is not throttled" do
      100.times do
        options "/api/v1/courts", headers: {
          "Origin" => "http://localhost:3001",
          "Access-Control-Request-Method" => "GET"
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
end
