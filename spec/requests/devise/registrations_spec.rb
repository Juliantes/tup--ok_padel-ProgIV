require "rails_helper"

RSpec.describe "Devise::Registrations", type: :request do
  describe "POST /users" do
    it "creates a user with required profile fields" do
      expect {
        post user_registration_path, params: {
          user: {
            email: "newplayer@example.com",
            name: "Nuevo Jugador",
            phone: "1155667788",
            self_level: 4,
            bio: "Jugador nuevo",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(User.last.self_level).to eq(4)
    end

    it "rejects sign up with an invalid phone" do
      expect {
        post user_registration_path, params: {
          user: {
            email: "invalid@example.com",
            name: "Invalid Phone",
            phone: "123",
            self_level: 4,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Teléfono")
    end
  end
end
