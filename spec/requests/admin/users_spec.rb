require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  describe "POST /admin/users" do
    it "creates a user with default player role" do
      expect {
        post admin_users_path, params: {
          user: {
            email: "newplayer@example.com",
            password: "password123",
            password_confirmation: "password123",
            name: "New Player",
            phone: "1199887766",
            self_level: 4,
            bio: "Ready to play"
          }
        }
      }.to change(User, :count).by(1)

      created_user = User.find_by!(email: "newplayer@example.com")
      expect(response).to redirect_to(admin_user_path(created_user))
      expect(created_user).to be_player
    end
  end

  describe "DELETE /admin/users/:id" do
    it "deletes a user without restrictions" do
      user = create(:user, :player)

      expect {
        delete admin_user_path(user)
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end

    it "does not delete a user who owns clubs" do
      club = create(:club)
      owner = club.owner

      expect {
        delete admin_user_path(owner)
      }.not_to change(User, :count)

      expect(response).to redirect_to(admin_user_path(owner))
      follow_redirect!
      expect(response.body).to include("alert alert-danger")
    end
  end
end
