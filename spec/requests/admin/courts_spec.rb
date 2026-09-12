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
end
