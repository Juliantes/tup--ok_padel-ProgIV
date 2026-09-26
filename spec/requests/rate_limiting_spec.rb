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

    it "throttles invalid Bearer tokens by IP" do
      20.times do
        post "/api/v1/matches",
             params: {},
             headers: { "Authorization" => "Bearer invalid" },
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      post "/api/v1/matches",
           params: {},
           headers: { "Authorization" => "Bearer invalid" },
           as: :json

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "GET /api/v1/courts with invalid Bearer" do
    it "throttles GET with invalid Bearer by IP" do
      60.times do
        get "/api/v1/courts", headers: { "Authorization" => "Bearer invalid" }, as: :json
        expect(response).to have_http_status(:ok)
      end

      get "/api/v1/courts", headers: { "Authorization" => "Bearer invalid" }, as: :json
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Fail2Ban" do
    let(:login_params) { { email: "missing@example.com", password: "wrong" } }

    it "bans an IP after 10 throttles in 10 minutes" do
      # login/ip limit is 5/min → 429 from the 6th request; 11 throttles need 16 POSTs
      16.times do
        post "/api/v1/login", params: login_params, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)

      post "/api/v1/login", params: login_params, as: :json
      expect(response).to have_http_status(:forbidden)
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
