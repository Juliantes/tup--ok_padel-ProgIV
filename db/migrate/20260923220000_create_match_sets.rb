class CreateMatchSets < ActiveRecord::Migration[8.1]
  def change
    create_table :match_sets do |t|
      t.references :match_result, null: false, foreign_key: true
      t.integer :order, null: false
      t.integer :team_a_games, null: false
      t.integer :team_b_games, null: false
      t.timestamps
    end

    add_index :match_sets, [ :match_result_id, :order ], unique: true
  end
end
