require "rails_helper"

RSpec.describe PlayerStat, type: :model do
  subject { build(:player_stat) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "#total_matches" do
    it "returns wins plus losses" do
      stat = build(:player_stat, wins: 3, losses: 2)

      expect(stat.total_matches).to eq(5)
    end
  end
end
