require "rails_helper"

RSpec.describe "Admin::MatchPlayers", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match) }
  let(:player) { create(:user, :player) }

  before { sign_in admin }

  describe "POST /admin/matches/:match_id/match_players" do
    it "adds a player to the match" do
      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            team: "team_a",
            status: "confirmed"
          }
        }
      }.to change(MatchPlayer, :count).by(1)

      expect(response).to redirect_to(edit_admin_match_path(match))
      expect(match.reload.match_players.pluck(:user_id)).to include(player.id)
    end

    it "does not add more than 4 active players" do
      create_list(:match_player, 2, match: match, team: :team_a)
      create_list(:match_player, 2, match: match, team: :team_b)

      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            team: "team_a",
            status: "confirmed"
          }
        }
      }.not_to change(MatchPlayer, :count)

      expect(response).to redirect_to(edit_admin_match_path(match))
      follow_redirect!
      expect(response.body).to include("already has 4 players")
    end

    it "does not add more than 2 players to the same pair" do
      create_list(:match_player, 2, match: match, team: :team_a)

      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            team: "team_a",
            status: "confirmed"
          }
        }
      }.not_to change(MatchPlayer, :count)

      expect(response).to redirect_to(edit_admin_match_path(match))
      follow_redirect!
      expect(response.body).to include("already has 2 players")
    end

    it "allows re-enrollment after cancellation" do
      create(:match_player, :cancelled, match: match, user: player, team: :team_a)

      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            team: "team_b",
            status: "confirmed"
          }
        }
      }.not_to change(MatchPlayer, :count)

      expect(response).to redirect_to(edit_admin_match_path(match))
      expect(match.match_players.find_by(user: player)).to be_confirmed
      expect(match.match_players.find_by(user: player).team).to eq("team_b")
    end

    it "does not add the same active player twice" do
      create(:match_player, match: match, user: player)

      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            team: "team_b",
            status: "confirmed"
          }
        }
      }.not_to change(MatchPlayer, :count)

      expect(response).to redirect_to(edit_admin_match_path(match))
      follow_redirect!
      expect(response.body).to include("alert alert-danger")
    end
  end

  describe "POST /admin/matches/:match_id/match_players in individual mode" do
    let(:match) { create(:match, :individual) }

    it "adds a player without a team" do
      expect {
        post admin_match_match_players_path(match), params: {
          match_player: {
            user_id: player.id,
            status: "confirmed"
          }
        }
      }.to change(MatchPlayer, :count).by(1)

      expect(match.match_players.find_by(user: player).team).to be_nil
    end
  end

  describe "DELETE /admin/matches/:match_id/match_players/:id" do
    it "removes a player from the match" do
      match_player = create(:match_player, match: match)

      expect {
        delete admin_match_match_player_path(match, match_player)
      }.to change(MatchPlayer, :count).by(-1)

      expect(response).to redirect_to(edit_admin_match_path(match))
    end
  end
end
