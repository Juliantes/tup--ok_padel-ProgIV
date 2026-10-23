# frozen_string_literal: true

require "rails_helper"

RSpec.describe FirebaseOAuthUserProvisioner do
  describe ".call" do
    let(:claims) do
      {
        "sub" => "uid-abc",
        "email" => "new.firebase@example.com",
        "name" => "Firebase New"
      }
    end

    it "creates a user with a valid placeholder phone and player role" do
      user = described_class.call(claims)

      expect(user).to be_persisted
      expect(user.phone).to match(/\A\+549\d{8}\z/)
      expect(user.self_level).to eq(3)
      expect(user.player?).to be(true)
    end

    it "returns the existing user when the email already exists" do
      existing = create(:user, :player, email: "new.firebase@example.com", name: "Keep Me")

      user = described_class.call(claims)

      expect(user.id).to eq(existing.id)
      expect(user.name).to eq("Keep Me")
    end
  end
end
