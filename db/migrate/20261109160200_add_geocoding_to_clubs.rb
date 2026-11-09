# frozen_string_literal: true

class AddGeocodingToClubs < ActiveRecord::Migration[8.1]
  def change
    change_table :clubs, bulk: true do |t|
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 11, scale: 7
      t.string :place_id, limit: 255
    end

    add_index :clubs, :place_id
  end
end
