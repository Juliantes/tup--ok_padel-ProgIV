class CreateMatchResults < ActiveRecord::Migration[8.0]
  def change
    create_table :match_results do |t|
      t.references :match, null: false, foreign_key: true, index: { unique: true }
      t.integer :team_a_score
      t.integer :team_b_score
      t.integer :winner_team
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end