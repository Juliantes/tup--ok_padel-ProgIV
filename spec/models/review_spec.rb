require "rails_helper"

RSpec.describe Review, type: :model do
  subject { build(:review) }

  describe "associations" do
    it { is_expected.to belong_to(:reviewer).class_name("User") }
    it { is_expected.to belong_to(:reviewed_user).class_name("User") }
    it { is_expected.to belong_to(:match) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:level_rating) }
    it { is_expected.to validate_presence_of(:stars) }
    it { is_expected.to validate_inclusion_of(:level_rating).in_range(PlayerCategory::RANGE) }
    it { is_expected.to validate_inclusion_of(:stars).in_range(1..5) }
  end

  describe "business rules" do
    it "does not allow self reviews" do
      user = create(:user, :player)
      review = build(:review, reviewer: user, reviewed_user: user)

      expect(review).not_to be_valid
      expect(review.errors[:reviewed_user]).to include("cannot be the same as reviewer")
    end
  end
end
