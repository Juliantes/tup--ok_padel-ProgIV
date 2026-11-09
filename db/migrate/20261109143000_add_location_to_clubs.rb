# frozen_string_literal: true

class AddLocationToClubs < ActiveRecord::Migration[8.1]
  def change
    change_table :clubs, bulk: true do |t|
      t.string :country, limit: 255
      t.string :province, limit: 255
      t.string :city, limit: 255
    end
  end
end
