require "rails_helper"

RSpec.describe "Admin::Courts", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "POST /admin/courts" do
    let(:club) { create(:club) }

    it "creates a court" do
      expect {
        post admin_courts_path, params: {
          court: {
            club_id: club.id,
            name: "Court A",
            court_type: "indoor",
            price_per_hour: 8000,
            status: "active",
            description: "Test court"
          }
        }
      }.to change(Court, :count).by(1)

      expect(response).to redirect_to(admin_court_path(Court.last))
    end
  end

  describe "PATCH /admin/courts/:id" do
    let(:court) { create(:court) }

    it "rejects price above database limit and re-renders the form" do
      patch admin_court_path(court), params: {
        court: {
          club_id: court.club_id,
          name: court.name,
          court_type: court.court_type,
          price_per_hour: "12341234123412341234",
          status: court.status,
          description: court.description
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Precio por hora")
      expect(court.reload.price_per_hour).not_to eq(BigDecimal("12341234123412341234"))
    end
  end
end
