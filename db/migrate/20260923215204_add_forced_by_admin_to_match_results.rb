class AddForcedByAdminToMatchResults < ActiveRecord::Migration[8.1]
  def change
    add_column :match_results, :forced_by_admin, :boolean, default: false, null: false
  end
end
