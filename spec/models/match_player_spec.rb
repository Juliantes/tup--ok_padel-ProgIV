require "rails_helper"

RSpec.describe MatchPlayer, type: :model do
  subject { build(:match_player) }

  describe "associations" do
    it { is_expected.to belong_to(:match) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:approved_by).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:match_id) }
  end

  describe "capacity" do
    it "does not allow more than 4 players in a match" do
      match = create(:match)
      4.times { create(:match_player, match: match) }
      extra_player = build(:match_player, match: match)

      expect(extra_player).not_to be_valid
      expect(extra_player.errors[:match]).to include("already has 4 players")
    end
  end
end
