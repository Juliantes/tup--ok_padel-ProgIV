# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_user, null: false, foreign_key: { to_table: :users }
      t.references :match, null: false, foreign_key: true
      t.integer :level_rating, null: false
      t.integer :stars, null: false
      t.text :comment
      t.boolean :is_upgradable, null: false, default: true

      t.timestamps
    end
  end
end
