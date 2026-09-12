# frozen_string_literal: true

class CreatePlayerStats < ActiveRecord::Migration[8.1]
  def change
    create_table :player_stats do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.decimal :win_rate, precision: 5, scale: 2, null: false, default: 0
      t.integer :current_streak, null: false, default: 0
      t.integer :best_streak, null: false, default: 0

      t.timestamps
    end
  end
end
