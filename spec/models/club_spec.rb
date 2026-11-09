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
    it { is_expected.to validate_inclusion_of(:card_theme).in_array(Club::CARD_THEMES) }
    it { is_expected.to validate_length_of(:country).is_at_most(255) }
    it { is_expected.to validate_length_of(:province).is_at_most(255) }
    it { is_expected.to validate_length_of(:city).is_at_most(255) }

    it "requires country, province, and city together" do
      club = build(:club, country: "Argentina", province: nil, city: "Rosario")

      expect(club).not_to be_valid
      expect(club.errors[:base]).to include("country, province, and city must all be present or all blank")
    end

    it "requires lat, lng, and place_id together" do
      club = build(:club, lat: BigDecimal("-34.6"), lng: nil, place_id: "place-1")

      expect(club).not_to be_valid
      expect(club.errors[:base]).to include("lat, lng, and place_id must all be present or all blank")
    end
  end
end
