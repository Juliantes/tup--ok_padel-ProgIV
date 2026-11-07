# frozen_string_literal: true

class AddColorToCourts < ActiveRecord::Migration[8.0]
  def change
    add_column :courts, :color, :integer, null: false, default: 0
  end
end
