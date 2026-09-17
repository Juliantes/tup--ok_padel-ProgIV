class AddRosterModeToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :roster_mode, :integer, default: 0, null: false
    add_index :matches, :roster_mode
  end
end
