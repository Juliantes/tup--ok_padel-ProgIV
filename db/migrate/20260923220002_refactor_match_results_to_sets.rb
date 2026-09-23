class RefactorMatchResultsToSets < ActiveRecord::Migration[8.1]
  def up
    MatchSet.delete_all if table_exists?(:match_sets)
    MatchResult.delete_all

    remove_column :match_results, :team_a_score, :integer
    remove_column :match_results, :team_b_score, :integer
    remove_column :match_results, :winner_team, :integer
  end

  def down
    add_column :match_results, :team_a_score, :integer
    add_column :match_results, :team_b_score, :integer
    add_column :match_results, :winner_team, :integer
  end
end
