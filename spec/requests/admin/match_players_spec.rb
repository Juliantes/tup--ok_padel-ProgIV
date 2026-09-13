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

    it "does not add more than 4 players" do
      create_list(:match_player, 4, match: match)

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

    it "does not add the same player twice" do
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
