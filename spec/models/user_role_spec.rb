require "rails_helper"

RSpec.describe UserRole, type: :model do
  subject { build(:user_role) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(User::ROLES) }
  end
end
