# frozen_string_literal: true

class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :court, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :time_slot, foreign_key: true
      t.datetime :date, null: false
      t.integer :duration, null: false
      t.integer :status, null: false, default: 0
      t.integer :level_required, null: false, default: 1

      t.timestamps
    end
  end
end
