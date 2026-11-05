# frozen_string_literal: true

class AddWalkInFieldsToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :walk_in_guest_name, :string
    add_column :matches, :walk_in_guest_phone, :string
    add_column :matches, :walk_in, :boolean, default: false, null: false

    add_index :matches,
              %i[time_slot_id date],
              unique: true,
              where: "time_slot_id IS NOT NULL AND status <> 4",
              name: "index_matches_unique_active_slot_date"
  end
end
