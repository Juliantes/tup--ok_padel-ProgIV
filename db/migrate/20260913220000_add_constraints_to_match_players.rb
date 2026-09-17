# frozen_string_literal: true

class AddConstraintsToMatchPlayers < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :match_players,
                         "status IN (0, 1, 2)",
                         name: "match_players_status_range"

    add_check_constraint :match_players,
                         "team IS NULL OR team IN (1, 2)",
                         name: "match_players_team_range"
  end
end
