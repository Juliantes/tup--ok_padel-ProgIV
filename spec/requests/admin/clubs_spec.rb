require "rails_helper"

RSpec.describe "Admin::Clubs", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:owner) { create(:user, :club_owner) }

  before { sign_in admin }

  describe "POST /admin/clubs" do
    it "creates a club" do
      expect {
        post admin_clubs_path, params: {
          club: {
            name: "Padel Central",
            address: "Av. Siempre Viva 742",
            phone: "1122334455",
            email: "info@padelcentral.com",
            owner_id: owner.id
          }
        }
      }.to change(Club, :count).by(1)

      expect(response).to redirect_to(admin_club_path(Club.last))
    end
  end

  describe "PATCH /admin/clubs/:id" do
    let(:club) { create(:club) }

    it "updates a club" do
      patch admin_club_path(club), params: {
        club: {
          name: "Updated Club Name",
          address: club.address,
          phone: club.phone,
          email: club.email,
          owner_id: club.owner_id
        }
      }

      expect(response).to redirect_to(admin_club_path(club))
      expect(club.reload.name).to eq("Updated Club Name")
    end
  end
end
