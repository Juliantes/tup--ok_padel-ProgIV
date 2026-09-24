require "rails_helper"

RSpec.describe AutoApproveResultsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:team_a_wins_2_0) do
    [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ]
  end

  let(:team_b_wins_2_0) do
    [ { team_a_games: 4, team_b_games: 6 }, { team_a_games: 4, team_b_games: 6 } ]
  end

  def disputed_match_with_reports(sets_a:, sets_b:, reported_at: Time.current)
    match = create(:match, :individual, status: :confirmed)
    player_a = create(:user, :player)
    player_b = create(:user, :player)
    create(:match_player, match: match, user: player_a, team: :team_a, status: :confirmed)
    create(:match_player, match: match, user: player_b, team: :team_b, status: :confirmed)

    travel_to reported_at do
      create(:match_result, match: match, reported_by: player_a, result_sets: sets_a)
      create(:match_result, match: match, reported_by: player_b, result_sets: sets_b)
    end

    match.reload
  end

  it "does not auto-approve when the last report is within the threshold" do
    match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0)
    expect(match).to be_reported

    described_class.perform_now

    expect(match.reload).to be_reported
    expect(match.auto_approved_at).to be_nil
  end

  it "auto-approves when the last report is older than the threshold" do
    match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0, reported_at: 3.days.ago)

    travel_to 3.days.from_now do
      described_class.perform_now
    end

    match.reload
    expect(match).to be_completed
    expect(match.auto_approved_at).to be_present
  end

  it "picks the report with the most votes" do
    match = create(:match, :individual, status: :confirmed)
    players = create_list(:user, 4, :player)
    players.each_with_index do |user, idx|
      team = idx == 3 ? :team_b : :team_a
      create(:match_player, match: match, user: user, team: team, status: :confirmed)
    end

    travel_to 3.days.ago do
      create(:match_result, match: match, reported_by: players[0], result_sets: team_a_wins_2_0)
      create(:match_result, match: match, reported_by: players[1], result_sets: team_a_wins_2_0)
      create(:match_result, match: match, reported_by: players[2], result_sets: team_a_wins_2_0)
      create(:match_result, match: match, reported_by: players[3], result_sets: team_b_wins_2_0)
    end
    match.update_columns(status: Match.statuses[:reported], stats_applied_at: nil)

    travel_to 3.days.from_now do
      described_class.perform_now
    end

    expect(match.reload).to be_completed
    expect(players[0].player_stat.reload.wins).to eq(2)
    expect(players[3].player_stat.reload.losses).to eq(2)
  end

  it "applies player stats once" do
    match, player_a, player_b = roster_match
    travel_to 3.days.ago do
      create(:match_result, match: match, reported_by: player_a, result_sets: team_a_wins_2_0)
      create(:match_result, match: match, reported_by: player_b, result_sets: team_b_wins_2_0)
    end
    wins_before = player_a.player_stat.reload.wins

    travel_to 3.days.from_now do
      described_class.perform_now
    end

    expect(match.reload.stats_applied_at).to be_present
    expect(player_a.player_stat.reload.wins).to eq(2)
  end

  it "skips matches that were already auto-approved" do
    match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0, reported_at: 3.days.ago)
    match.update!(status: :completed, auto_approved_at: 1.day.ago, stats_applied_at: 1.day.ago)

    travel_to 3.days.from_now do
      expect { described_class.perform_now }.not_to change { match.reload.updated_at }
    end
  end

  it "is idempotent across runs" do
    match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0, reported_at: 3.days.ago)

    travel_to 3.days.from_now do
      described_class.perform_now
      approved_at = match.reload.auto_approved_at
      described_class.perform_now
      expect(match.reload.auto_approved_at).to eq(approved_at)
    end
  end

  it "logs errors per match without aborting the job" do
    ok_match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0, reported_at: 3.days.ago)
    bad_match = disputed_match_with_reports(sets_a: team_a_wins_2_0, sets_b: team_b_wins_2_0, reported_at: 3.days.ago)

    allow(Match).to receive(:pending_auto_approval).and_return(Match.where(id: [ bad_match.id, ok_match.id ]))
    allow_any_instance_of(Match).to receive(:auto_approve_result!).and_wrap_original do |method, *args|
      raise StandardError, "boom" if method.receiver.id == bad_match.id

      method.call(*args)
    end

    expect(Rails.logger).to receive(:error).with(/\[AutoApproveResultsJob\] match_id=#{bad_match.id}/)

    travel_to 3.days.from_now do
      described_class.perform_now
    end

    expect(ok_match.reload).to be_completed
    expect(bad_match.reload).to be_reported
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
