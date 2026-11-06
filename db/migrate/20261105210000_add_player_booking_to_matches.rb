# frozen_string_literal: true

class AddPlayerBookingToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :player_booking, :boolean, default: false, null: false
  end
end
