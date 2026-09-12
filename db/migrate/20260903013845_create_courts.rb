# frozen_string_literal: true

class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.references :club, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :court_type, null: false, default: 0
      t.decimal :price_per_hour, precision: 10, scale: 2, null: false
      t.text :description
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :courts, [ :club_id, :name ], unique: true
  end
end
