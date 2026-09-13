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
    it {
      is_expected.to validate_numericality_of(:price_per_hour)
        .is_less_than_or_equal_to(Court::MAX_PRICE_PER_HOUR)
    }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:club_id) }

    it "rejects zero price" do
      court = build(:court, price_per_hour: 0)

      expect(court).not_to be_valid
      expect(court.errors[:price_per_hour]).to be_present
    end

    it "rejects negative price" do
      court = build(:court, price_per_hour: -1)

      expect(court).not_to be_valid
      expect(court.errors[:price_per_hour]).to be_present
    end

    it "rejects price above database limit" do
      court = build(:court, price_per_hour: 100_000_000)

      expect(court).not_to be_valid
      expect(court.errors[:price_per_hour]).to be_present
    end

    it "accepts maximum allowed price" do
      court = build(:court, price_per_hour: Court::MAX_PRICE_PER_HOUR)

      expect(court).to be_valid
    end

    it "rejects unsupported image content types" do
      court = build(:court)
      court.image.attach(
        io: StringIO.new("not an image"),
        filename: "test.txt",
        content_type: "text/plain"
      )

      expect(court).not_to be_valid
      expect(court.errors[:image]).to be_present
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:court_type).with_values(indoor: 0, outdoor: 1) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, maintenance: 1, inactive: 2) }
  end
end
