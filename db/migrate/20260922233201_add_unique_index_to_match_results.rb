# frozen_string_literal: true

class AddUniqueIndexToMatchResults < ActiveRecord::Migration[8.1]
  def up
    # has_one used a unique index on match_id. Several reports per match need it gone.
    # If this fails on duplicate (match_id, reported_by_id) rows, run `bin/rails db:reset`.
    remove_index :match_results, name: "index_match_results_on_match_id"
    add_index :match_results, [ :match_id, :reported_by_id ],
              unique: true,
              name: "index_match_results_on_match_and_reporter"
  end

  def down
    remove_index :match_results, name: "index_match_results_on_match_and_reporter"
    add_index :match_results, :match_id, unique: true, name: "index_match_results_on_match_id"
  end
end
