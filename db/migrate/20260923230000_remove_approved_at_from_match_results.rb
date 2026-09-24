class RemoveApprovedAtFromMatchResults < ActiveRecord::Migration[8.1]
  def change
    remove_column :match_results, :approved_at, :datetime
  end
end
