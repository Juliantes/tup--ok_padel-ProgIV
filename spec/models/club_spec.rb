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
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:address).is_at_most(255) }
    it { is_expected.to validate_length_of(:phone).is_at_most(255) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to allow_value("1144556677").for(:phone) }
    it { is_expected.not_to allow_value("abc").for(:phone) }
  end
end
