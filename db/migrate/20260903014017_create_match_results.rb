# frozen_string_literal: true

class CreateMatchResults < ActiveRecord::Migration[8.1]
  def change
    create_table :match_results do |t|
      t.references :match, null: false, foreign_key: true
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.integer :team_a_score
      t.integer :team_b_score
      t.integer :winner_team
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
