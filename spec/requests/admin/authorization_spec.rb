require "rails_helper"

RSpec.describe "Admin authorization", type: :request do
  describe "GET /admin/courts" do
    it "redirects guests to sign in" do
      get admin_courts_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      sign_in create(:user, :player)

      get admin_courts_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have permission to access the back office.")
    end

    it "allows admin users" do
      sign_in create(:user, :admin)

      get admin_courts_path

      expect(response).to have_http_status(:ok)
    end
  end
end
