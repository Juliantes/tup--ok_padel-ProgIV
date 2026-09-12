# frozen_string_literal: true

class CreateMatchPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :match_players do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :team
      t.references :approved_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :match_players, [ :match_id, :user_id ], unique: true
  end
end
