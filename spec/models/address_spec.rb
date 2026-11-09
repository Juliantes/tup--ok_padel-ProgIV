# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address, type: :model do
  describe "validations" do
    subject { build(:address) }

    it { is_expected.to validate_presence_of(:formatted) }
    it { is_expected.to validate_presence_of(:place_id) }
    it { is_expected.to validate_uniqueness_of(:place_id) }
    it { is_expected.to validate_presence_of(:lat) }
    it { is_expected.to validate_presence_of(:lng) }
  end

  describe ".prefix_search" do
    let!(:match) { create(:address, city: "La Plata", street: "Calle 50", formatted: "Calle 50, La Plata") }
    let!(:other) { create(:address, city: "Rosario", street: "Mitre", formatted: "Mitre, Rosario") }

    it "matches city with trailing wildcard only" do
      expect(described_class.prefix_search("La Plat")).to contain_exactly(match)
    end

    it "matches street prefix" do
      expect(described_class.prefix_search("Calle 5")).to contain_exactly(match)
    end

    it "does not match substring in the middle of city" do
      expect(described_class.prefix_search("Plata")).to be_empty
    end

    it "returns empty for blank query" do
      expect(described_class.prefix_search("  ")).to be_empty
    end
  end
end
