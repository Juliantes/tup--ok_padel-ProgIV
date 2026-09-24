require "rails_helper"

RSpec.describe Match, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  subject { build(:match) }

  describe "associations" do
    it { is_expected.to belong_to(:court) }
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to belong_to(:time_slot).optional }
    it { is_expected.to have_many(:match_results).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).only_integer.is_greater_than(0) }
    it {
      is_expected.to validate_numericality_of(:duration)
        .only_integer
        .is_less_than_or_equal_to(Match::MAX_DURATION)
    }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:roster_mode).with_values(pairs: 0, individual: 1).with_prefix(:roster_mode) }
    it {
      is_expected.to define_enum_for(:status).with_values(
        open: 0, full: 1, confirmed: 2, completed: 3, cancelled: 4, reported: 5
      )
    }
  end

  describe "roster" do
    context "in pairs mode" do
      let(:match) { create(:match, status: :open, roster_mode: :pairs) }

      it "is complete when both pairs have two players" do
        create_list(:match_player, 2, match: match, team: :team_a)
        create_list(:match_player, 2, match: match, team: :team_b)

        expect(match.roster_complete?).to be(true)
        expect(match.team_roster_full?(:team_a)).to be(true)
        expect(match.team_roster_full?(:team_b)).to be(true)
      end

      it "is not complete when a pair is missing players" do
        create(:match_player, match: match, team: :team_a)

        expect(match.roster_complete?).to be(false)
        expect(match.team_roster_full?(:team_a)).to be(false)
      end

      it "does not allow switching from individual to pairs when players have no team" do
        individual_match = create(:match, :individual)
        create(:match_player, :without_team, match: individual_match)

        expect(individual_match.update(roster_mode: :pairs)).to be(false)
        expect(individual_match.errors[:roster_mode]).to be_present
      end
    end

    context "in individual mode" do
      let(:match) { create(:match, :individual, status: :open) }

      it "is complete with four active players regardless of team" do
        create_list(:match_player, 4, match: match, team: :team_a)

        expect(match.roster_complete?).to be(true)
      end

      it "is not complete with fewer than four players" do
        create_list(:match_player, 3, match: match)

        expect(match.roster_complete?).to be(false)
      end

      it "marks the match as full with four individual players" do
        create_list(:match_player, 4, match: match, team: nil)

        expect(match.reload).to be_full
      end
    end
  end

  describe "custom validations" do
    it "rejects a time slot from another court" do
      court = create(:court)
      other_court = create(:court)
      time_slot = create(:time_slot, court: other_court, day_of_week: 1)
      match = build(:match, court: court, time_slot: time_slot, date: next_monday)

      expect(match).not_to be_valid
      expect(match.errors[:time_slot]).to include("must belong to the same court")
    end

    it "rejects a time slot whose day does not match the match date" do
      court = create(:court)
      time_slot = create(:time_slot, court: court, day_of_week: 2)
      match = build(:match, court: court, time_slot: time_slot, date: next_monday)

      expect(match).not_to be_valid
      expect(match.errors[:time_slot]).to include("day of week must match match date")
    end
  end

  describe "#consensus_result" do
    let(:match) { create(:match, :individual, status: :confirmed) }

    it "treats a single report as provisional consensus" do
      add_report(match, sets: team_a_wins_2_0)

      expect(match.consensus_result).to include(votes: 1, total: 1, signature: "6-4,6-4")
    end

    it "accepts two identical reports" do
      2.times { add_report(match, sets: team_a_wins_2_0) }

      expect(match.consensus_result).to include(votes: 2, total: 2, signature: "6-4,6-4")
    end

    it "returns nil when two reports differ" do
      add_report(match, sets: team_a_wins_2_0)
      add_report(match, sets: team_b_wins_2_0)

      expect(match.consensus_result).to be_nil
    end

    it "accepts a strict majority of three reports" do
      2.times { add_report(match, sets: team_a_wins_2_0) }
      add_report(match, sets: team_b_wins_2_0)

      expect(match.consensus_result).to include(votes: 2, total: 3, signature: "6-4,6-4")
    end

    it "returns nil when three reports all differ" do
      add_report(match, sets: team_a_wins_2_0)
      add_report(match, sets: team_b_wins_2_0)
      add_report(match, sets: team_a_wins_2_1)

      expect(match.consensus_result).to be_nil
    end

    it "accepts three of four identical reports" do
      3.times { add_report(match, sets: team_a_wins_2_0) }
      add_report(match, sets: team_b_wins_2_1)

      expect(match.consensus_result).to include(votes: 3, total: 4)
    end

    it "returns nil on a 2-2 split" do
      2.times { add_report(match, sets: team_a_wins_2_0) }
      2.times { add_report(match, sets: team_b_wins_2_0) }

      expect(match.consensus_result).to be_nil
    end
  end

  describe "#recalculate_consensus!" do
    it "moves a reported match back to confirmed when no reports remain" do
      match = create(:match, status: :reported)

      match.recalculate_consensus!

      expect(match.reload).to be_confirmed
    end

    it "marks the match reported when scores disagree" do
      match = create(:match, :individual, status: :confirmed)
      add_report(match, sets: team_a_wins_2_0)
      add_report(match, sets: team_b_wins_2_0)

      expect(match.reload).to be_reported
    end

    it "marks the match completed when there is consensus" do
      match = create(:match, :individual, status: :confirmed)
      add_report(match, sets: team_a_wins_2_0)

      expect(match.reload).to be_completed
      expect(match.stats_applied_at).to be_present
    end

    it "does not apply stats twice" do
      match, player_a, = roster_match
      add_report_for(match, player_a, sets: team_a_wins_2_0)
      applied_at = match.reload.stats_applied_at

      expect {
        match.recalculate_consensus!
      }.not_to change { player_a.player_stat.reload.wins }

      expect(match.reload.stats_applied_at).to eq(applied_at)
    end
  end

  describe "#report_result!" do
    it "creates a report for an active player" do
      match, player_a, = roster_match

      result = match.report_result!(reporter: player_a, sets: team_a_wins_2_0)

      expect(result).to be_persisted
      expect(match.reload).to be_completed
    end

    it "rejects a reporter who is not an active player" do
      match = create(:match, status: :confirmed)
      outsider = create(:user, :player)

      expect {
        match.report_result!(reporter: outsider, sets: team_a_wins_2_0)
      }.to raise_error(ActiveRecord::RecordInvalid, /not an active player/)
    end

    it "rejects a second report once consensus is reached" do
      match, player_a, = roster_match
      match.report_result!(reporter: player_a, sets: team_a_wins_2_0)

      expect {
        match.report_result!(reporter: player_a, sets: team_a_wins_2_0_alt)
      }.to raise_error(ActiveRecord::RecordInvalid, /already reported/)
      expect(match.match_results.count).to eq(1)
    end

    it "replaces the previous report while the match is reported and keeps the old row if the new one is invalid" do
      match, player_a, player_b = roster_match
      match.report_result!(reporter: player_a, sets: team_a_wins_2_0)
      match.report_result!(reporter: player_b, sets: team_b_wins_2_0)
      expect(match.reload).to be_reported
      wins_before = player_a.player_stat.reload.wins

      expect {
        match.report_result!(reporter: player_a, sets: invalid_set_match)
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(match.match_results.find_by!(reported_by: player_a).set_signature).to eq("6-4,6-4")
      expect(player_a.player_stat.reload.wins).to eq(wins_before)

      match.report_result!(reporter: player_a, sets: team_b_wins_2_0)

      expect(match.match_results.where(reported_by: player_a).count).to eq(1)
      expect(match.reload).to be_completed
      expect(player_a.player_stat.reload.wins).to eq(wins_before)
    end

    it "rejects new reports after auto-approval" do
      match, player_a, player_b = roster_match
      add_report_for(match, player_a, sets: team_a_wins_2_0)
      add_report_for(match, player_b, sets: team_b_wins_2_0)
      match.auto_approve_result!
      other = create(:user, :player)
      create(:match_player, match: match, user: other, team: :team_b, status: :confirmed)

      expect {
        match.report_result!(reporter: other, sets: team_a_wins_2_0)
      }.to raise_error(ActiveRecord::RecordInvalid, /finalized/)
    end
  end

  describe "#force_result!" do
    it "creates a forced report, completes the match, and applies stats ignoring prior dispute" do
      match, player_a, player_b = roster_match
      admin = create(:user, :admin)
      add_report_for(match, player_a, sets: team_a_wins_2_0)
      add_report_for(match, player_b, sets: team_b_wins_2_0)
      expect(match.reload).to be_reported

      match.force_result!(admin: admin, sets: team_a_wins_2_1)

      forced = match.match_results.find_by!(reported_by: admin)
      expect(forced).to be_forced_by_admin
      expect(match.reload).to be_completed
      expect(player_a.player_stat.reload.wins).to eq(2)
      expect(player_b.player_stat.reload.losses).to eq(2)
    end
  end

  describe "#apply_stats_from!" do
    it "applies player stats from explicit winner" do
      match, player_a, player_b = roster_match

      match.apply_stats_from!(winner_team: :team_a)

      expect(match.reload.stats_applied_at).to be_present
      expect(player_a.player_stat.reload.wins).to eq(2)
      expect(player_b.player_stat.reload.losses).to eq(2)
    end
  end

  describe ".pending_auto_approval" do
    it "includes reported matches whose last report is older than the threshold" do
      match = create(:match, status: :reported)
      travel_to 3.days.ago do
        add_report(match, sets: team_a_wins_2_0)
        add_report(match, sets: team_b_wins_2_0)
      end

      expect(Match.pending_auto_approval(threshold_hours: 48)).to include(match)
    end

    it "excludes matches that are not in reported status" do
      match = create(:match, status: :confirmed)
      travel_to 3.days.ago { add_report(match, sets: team_a_wins_2_0) }

      expect(Match.pending_auto_approval(threshold_hours: 48)).not_to include(match)
    end

    it "excludes reported matches with a recent last report" do
      match = create(:match, status: :reported)
      add_report(match, sets: team_a_wins_2_0)
      add_report(match, sets: team_b_wins_2_0)

      expect(Match.pending_auto_approval(threshold_hours: 48)).not_to include(match)
    end
  end

  describe "#auto_approve_result!" do
    it "completes a disputed match with the only report in the winning group" do
      match, player_a, player_b = roster_match
      travel_to 3.days.ago do
        add_report_for(match, player_a, sets: team_a_wins_2_0)
        add_report_for(match, player_b, sets: team_b_wins_2_0)
      end

      match.auto_approve_result!

      expect(match.reload).to be_completed
      expect(match.auto_approved_at).to be_present
      expect(player_a.player_stat.reload.wins).to eq(2)
    end

    it "chooses the signature with the most votes" do
      match = create(:match, :individual, status: :reported)
      players = create_list(:user, 4, :player)
      players.each_with_index do |user, idx|
        team = idx == 3 ? :team_b : :team_a
        create(:match_player, match: match, user: user, team: team, status: :confirmed)
      end
      add_report_for(match, players[0], sets: team_a_wins_2_0)
      add_report_for(match, players[1], sets: team_a_wins_2_0)
      add_report_for(match, players[2], sets: team_a_wins_2_0)
      add_report_for(match, players[3], sets: team_b_wins_2_0)
      match.update_columns(status: Match.statuses[:reported], stats_applied_at: nil)

      match.auto_approve_result!

      expect(players[0].player_stat.reload.wins).to eq(2)
      expect(players[3].player_stat.reload.losses).to eq(2)
    end

    it "breaks vote ties by the oldest report in the winning group" do
      match = create(:match, :individual, status: :confirmed)
      players = create_list(:user, 4, :player)
      teams = [ :team_a, :team_b, :team_b, :team_a ]
      players.each_with_index do |user, idx|
        create(:match_player, match: match, user: user, team: teams[idx], status: :confirmed)
      end

      reports = [
        [ players[0], team_a_wins_2_0, 5.days.ago ],
        [ players[1], team_b_wins_2_0, 4.days.ago ],
        [ players[2], team_b_wins_2_0, 3.days.ago ],
        [ players[3], team_a_wins_2_0, 3.days.ago ]
      ]

      MatchResult.skip_callback(:commit, :after, :recalculate_consensus_after_create)
      begin
        reports.each do |reporter, sets, reported_at|
          travel_to reported_at do
            create(:match_result, match: match, reported_by: reporter, result_sets: sets)
          end
        end
      ensure
        MatchResult.set_callback(:commit, :after, :recalculate_consensus_after_create)
      end

      match.update_columns(status: Match.statuses[:reported], stats_applied_at: nil)
      players.each { |user| user.player_stat.update!(wins: 0, losses: 0, current_streak: 0, best_streak: 0, win_rate: 0) }

      expect(match.reload).to be_reported

      match.auto_approve_result!

      expect(match.reload.auto_approved_at).to be_present
      expect(players[0].player_stat.reload.wins).to eq(1)
      expect(players[1].player_stat.reload.losses).to eq(1)
    end

    it "does nothing when auto_approved_at is already set" do
      match = create(:match, status: :reported, auto_approved_at: 1.hour.ago)
      add_report(match, sets: team_a_wins_2_0)

      expect { match.auto_approve_result! }.not_to change { match.reload.status }
    end

    it "does not apply stats twice" do
      match, player_a, player_b = roster_match
      add_report_for(match, player_a, sets: team_a_wins_2_0)
      add_report_for(match, player_b, sets: team_b_wins_2_0)
      match.auto_approve_result!
      applied_at = match.reload.stats_applied_at
      wins = player_a.player_stat.reload.wins

      match.auto_approve_result!

      expect(match.reload.stats_applied_at).to eq(applied_at)
      expect(player_a.player_stat.reload.wins).to eq(wins)
    end
  end

  describe "#mark_as_played!" do
    it "marks the match completed without a result" do
      match = create(:match, status: :confirmed)

      match.mark_as_played!

      expect(match).to be_completed
      expect(match.stats_applied_at).to be_nil
    end

    it "leaves an already completed match unchanged" do
      match = create(:match, status: :completed)

      expect { match.mark_as_played! }.not_to change { match.reload.updated_at }
      expect(match).to be_completed
    end
  end

  describe "player stats from consensus" do
    it "gives the win, streak and best streak to team A and a loss to team B" do
      match, player_a, player_b = roster_match
      add_report_for(match, player_a, sets: team_a_wins_2_0)

      expect(player_a.player_stat.reload).to have_attributes(wins: 2, losses: 1, current_streak: 3, best_streak: 3)
      expect(player_b.player_stat.reload).to have_attributes(wins: 1, losses: 2, current_streak: 0, best_streak: 4)
      expect(player_a.player_stat.win_rate.to_f).to be_within(0.001).of(66.67)
      expect(player_b.player_stat.win_rate.to_f).to be_within(0.001).of(33.33)
    end

    it "gives the win to team B" do
      match, player_a, player_b = roster_match
      add_report_for(match, player_b, sets: team_b_wins_2_0)

      expect(player_b.player_stat.reload.wins).to eq(2)
      expect(player_a.player_stat.reload.losses).to eq(2)
      expect(player_a.player_stat.current_streak).to eq(0)
    end
  end

  def next_monday
    Date.current.next_occurring(:monday).change(hour: 10)
  end

  def team_a_wins_2_0
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  def team_a_wins_2_0_alt
    [ { team_a_games: 6, team_b_games: 2 }, { team_a_games: 6, team_b_games: 3 } ]
  end

  def team_a_wins_2_1
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 4, team_b_games: 6 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  def team_b_wins_2_0
    [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
  end

  def team_b_wins_2_1
    [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 6, team_b_games: 4 }, { team_a_games: 4, team_b_games: 6 } ]
  end

  def invalid_set_match
    [ { team_a_games: 6, team_b_games: 5 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  def add_report(match, sets:, team: :team_a)
    user = create(:user, :player)
    create(:match_player, match: match, user: user, team: team, status: :confirmed)
    add_report_for(match, user, sets: sets)
  end

  def add_report_for(match, user, sets:)
    create(:match_player, match: match, user: user, team: :team_a, status: :confirmed) unless match.match_players.exists?(user_id: user.id)
    create(:match_result, match: match, reported_by: user, result_sets: sets)
  end

  def roster_match
    match = create(:match, :individual, status: :confirmed)
    player_a = create(:user, :player)
    player_b = create(:user, :player)
    player_a.player_stat.update!(wins: 1, losses: 1, current_streak: 2, best_streak: 2, win_rate: 50)
    player_b.player_stat.update!(wins: 1, losses: 1, current_streak: 4, best_streak: 4, win_rate: 50)
    create(:match_player, match: match, user: player_a, team: :team_a, status: :confirmed)
    create(:match_player, match: match, user: player_b, team: :team_b, status: :confirmed)
    [ match, player_a, player_b ]
  end
end
