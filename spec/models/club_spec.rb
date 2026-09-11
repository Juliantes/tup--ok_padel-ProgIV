require "rails_helper"

RSpec.describe Club, type: :model do
  subject { build(:club) }

  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User") }
    it { is_expected.to have_many(:courts).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:phone) }
  end
end
