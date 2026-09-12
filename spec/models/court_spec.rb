require "rails_helper"

RSpec.describe Court, type: :model do
  subject { build(:court) }

  describe "associations" do
    it { is_expected.to belong_to(:club) }
    it { is_expected.to have_many(:time_slots).dependent(:destroy) }
    it { is_expected.to have_many(:matches).dependent(:restrict_with_error) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:price_per_hour) }
    it { is_expected.to validate_numericality_of(:price_per_hour).is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:club_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:court_type).with_values(indoor: 0, outdoor: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, maintenance: 1, inactive: 2) }
  end
end
