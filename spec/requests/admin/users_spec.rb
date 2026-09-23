require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in admin }

  def role_params_for(user, **overrides)
    User::ROLES.each_with_object({}) do |role, hash|
      current = user.has_role?(role)
      hash["role_#{role}"] = overrides.fetch(role.to_sym, current ? "1" : "0")
    end
  end

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

  describe "DELETE /admin/users/:id (last admin)" do
    let!(:sole_admin) { create(:user, :admin) }
    let(:admin) { sole_admin }

    it "blocks deleting the last admin" do
      expect {
        delete admin_user_path(sole_admin)
      }.not_to change(User, :count)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to eq("Cannot delete the last admin.")
      expect(sole_admin.reload.admin?).to be(true)
    end

    it "allows deleting an admin when another admin exists" do
      other = create(:user, :admin)

      expect {
        delete admin_user_path(other)
      }.to change(User, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
      expect(sole_admin.reload.admin?).to be(true)
    end
  end

  describe "removing admin role from the last admin" do
    let!(:sole_admin) { create(:user, :admin) }
    let(:admin) { sole_admin }

    it "prevents removing admin role from the last admin" do
      patch admin_user_path(sole_admin), params: {
        user: {
          name: sole_admin.name,
          phone: sole_admin.phone,
          self_level: sole_admin.self_level
        }.merge(role_params_for(sole_admin, admin: "0"))
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(sole_admin.reload.admin?).to be(true)
      expect(response.body).to include("Cannot remove the last admin role")
    end

    it "allows removing admin role when another admin exists" do
      other_admin = create(:user, :admin)

      patch admin_user_path(other_admin), params: {
        user: {
          name: other_admin.name,
          phone: other_admin.phone,
          self_level: other_admin.self_level
        }.merge(role_params_for(other_admin, admin: "0"))
      }

      expect(response).to redirect_to(admin_user_path(other_admin))
      expect(other_admin.reload.admin?).to be(false)
      expect(sole_admin.reload.admin?).to be(true)
    end

    it "shows disabled checkbox for last admin in the form" do
      get edit_admin_user_path(sole_admin)

      expect(response.body).to include("Cannot remove the last admin role")
    end
  end
end
