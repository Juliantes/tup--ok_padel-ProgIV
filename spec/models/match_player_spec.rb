require "rails_helper"

RSpec.describe MatchPlayer, type: :model do
  subject { build(:match_player) }

  describe "associations" do
    it { is_expected.to belong_to(:match) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:approved_by).class_name("User").optional }
  end

  describe "validations" do
    subject { create(:match_player) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:match_id) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, confirmed: 1, cancelled: 2) }
    it { is_expected.to define_enum_for(:team).with_values(team_a: 1, team_b: 2).with_prefix(:team) }
  end

  describe "valid records" do
    it "is valid with default factory attributes" do
      expect(build(:match_player)).to be_valid
    end

    it "allows nil team in individual mode" do
      match = create(:match, :individual)

      expect(build(:match_player, :without_team, match: match)).to be_valid
    end

    it "requires a team in pairs mode" do
      match = create(:match, roster_mode: :pairs)

      expect(build(:match_player, :without_team, match: match)).not_to be_valid
    end

    it "allows nil approved_by" do
      expect(build(:match_player, approved_by: nil)).to be_valid
    end
  end

  describe "uniqueness" do
    it "does not allow the same user twice in the same match" do
      match = create(:match)
      user = create(:user, :player)
      create(:match_player, match: match, user: user)
      duplicate = build(:match_player, match: match, user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe ".enroll" do
    let(:match) { create(:match) }
    let(:user) { create(:user, :player) }

    it "creates a new enrollment" do
      expect {
        described_class.enroll(match: match, user: user, team: :team_a, status: :confirmed)
      }.to change(described_class, :count).by(1)
    end

    it "reactivates a cancelled enrollment" do
      enrollment = create(:match_player, :cancelled, match: match, user: user, team: :team_a)

      expect {
        described_class.enroll(match: match, user: user, team: :team_b, status: :confirmed)
      }.not_to change(described_class, :count)

      expect(enrollment.reload).to be_confirmed
      expect(enrollment.team).to eq("team_b")
      expect(enrollment.cancelled_at).to be_nil
    end

    it "raises when the user is already actively enrolled" do
      create(:match_player, match: match, user: user)

      expect {
        described_class.enroll(match: match, user: user, team: :team_b)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "audit timestamps" do
    it "sets joined_at on create" do
      match_player = create(:match_player)

      expect(match_player.joined_at).to be_present
    end

    it "sets cancelled_at when status changes to cancelled" do
      match_player = create(:match_player)

      match_player.update!(status: :cancelled)

      expect(match_player.cancelled_at).to be_present
    end

    it "clears cancelled_at and refreshes joined_at when reactivated" do
      match_player = create(:match_player, :cancelled)

      match_player.update!(status: :confirmed)

      expect(match_player.cancelled_at).to be_nil
      expect(match_player.joined_at).to be_present
    end
  end

  describe "capacity" do
    let(:match) { create(:match, roster_mode: :pairs) }

    it "allows the fourth active player when pairs are balanced" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create(:match_player, match: match, team: :team_b)
      fourth_player = build(:match_player, match: match, team: :team_b)

      expect(fourth_player).to be_valid
    end

    it "does not allow more than #{MatchPlayer::MAX_PLAYERS} active players in a match" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create_list(:match_player, 2, match: match, team: :team_b)
      extra_player = build(:match_player, match: match, team: :team_a)

      expect(extra_player).not_to be_valid
      expect(extra_player.errors[:match]).to include("already has #{MatchPlayer::MAX_PLAYERS} players")
    end

    it "does not allow more than #{MatchPlayer::PLAYERS_PER_TEAM} players in a pair" do
      create_list(:match_player, 2, match: match, team: :team_a)
      extra_player = build(:match_player, match: match, team: :team_a)

      expect(extra_player).not_to be_valid
      expect(extra_player.errors[:team]).to include("already has #{MatchPlayer::PLAYERS_PER_TEAM} players")
    end

    it "does not allow moving a player to a full pair on update" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create_list(:match_player, 2, match: match, team: :team_b)
      existing_player = match.match_players.team_team_a.first

      existing_player.team = :team_b

      expect(existing_player).not_to be_valid
      expect(existing_player.errors[:team]).to include("already has #{MatchPlayer::PLAYERS_PER_TEAM} players")
    end

    it "does not count cancelled players toward capacity" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create(:match_player, match: match, team: :team_b)
      create(:match_player, :cancelled, match: match, team: :team_b)
      replacement_player = build(:match_player, match: match, team: :team_b)

      expect(replacement_player).to be_valid
    end

    it "does not raise when match is blank" do
      match_player = build(:match_player, match: nil)

      expect { match_player.valid? }.not_to raise_error
    end

    context "in individual mode" do
      let(:match) { create(:match, :individual) }

      it "allows four players without teams" do
        3.times { create(:match_player, :without_team, match: match) }
        fourth_player = build(:match_player, :without_team, match: match)

        expect(fourth_player).to be_valid
      end

      it "allows four players on the same team" do
        3.times { create(:match_player, match: match, team: :team_a) }
        fourth_player = build(:match_player, match: match, team: :team_a)

        expect(fourth_player).to be_valid
      end
    end
  end

  describe "match roster status" do
    let(:match) { create(:match, status: :open) }

    it "marks the match as full when both pairs are complete" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create_list(:match_player, 2, match: match, team: :team_b)

      expect(match.reload).to be_full
    end

    it "reopens the match when a player is cancelled" do
      create_list(:match_player, 2, match: match, team: :team_a)
      players = create_list(:match_player, 2, match: match, team: :team_b)
      expect(match.reload).to be_full

      players.first.update!(status: :cancelled)

      expect(match.reload).to be_open
    end
  end
end
