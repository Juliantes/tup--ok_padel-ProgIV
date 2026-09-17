require "rails_helper"

RSpec.describe PlayerStat, type: :model do
  subject { build(:player_stat) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:win_rate).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:win_rate).is_less_than_or_equal_to(PlayerStat::MAX_WIN_RATE) }

    it "rejects negative wins" do
      stat = build(:player_stat, wins: -1)

      expect(stat).not_to be_valid
      expect(stat.errors[:wins]).to be_present
    end
  end

  describe "#total_matches" do
    it "returns wins plus losses" do
      stat = build(:player_stat, wins: 3, losses: 2)

      expect(stat.total_matches).to eq(5)
    end
  end
end
