require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }
    it { is_expected.to have_one(:player_stat).dependent(:destroy) }
    it { is_expected.to have_one_attached(:avatar) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:phone) }
    it { is_expected.to validate_presence_of(:self_level) }
    it { is_expected.to validate_inclusion_of(:self_level).in_range(User::SELF_LEVEL_RANGE) }
    it { is_expected.to validate_uniqueness_of(:phone).case_insensitive }
  end

  describe "callbacks" do
    it "creates a player stat after create" do
      user = create(:user)

      expect(user.player_stat).to be_present
    end
  end

  describe "#has_role?" do
    it "returns true when the user has the role" do
      user = create(:user, :admin)

      expect(user).to be_admin
      expect(user).to have_role(:admin)
    end

    it "returns false when the user does not have the role" do
      user = create(:user, :player)

      expect(user).not_to be_admin
    end
  end
end
