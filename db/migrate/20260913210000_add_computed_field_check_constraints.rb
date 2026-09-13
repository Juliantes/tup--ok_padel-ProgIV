# frozen_string_literal: true

class AddComputedFieldCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :users,
                         "average_level >= 0::numeric AND average_level <= 99.9",
                         name: "users_average_level_range"

    add_check_constraint :users,
                         "average_stars >= 0::numeric AND average_stars <= 9.99",
                         name: "users_average_stars_range"

    add_check_constraint :player_stats,
                         "win_rate >= 0::numeric AND win_rate <= 100",
                         name: "player_stats_win_rate_range"

    add_check_constraint :matches,
                         "duration > 0 AND duration <= 240",
                         name: "matches_duration_range"
  end
end
