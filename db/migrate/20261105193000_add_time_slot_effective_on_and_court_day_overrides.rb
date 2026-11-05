# frozen_string_literal: true

class AddTimeSlotEffectiveOnAndCourtDayOverrides < ActiveRecord::Migration[8.1]
  def change
    create_table :court_day_overrides do |t|
      t.references :court, null: false, foreign_key: true
      t.date :date, null: false

      t.timestamps
    end

    add_index :court_day_overrides, [ :court_id, :date ], unique: true

    add_column :time_slots, :effective_on, :date

    remove_index :time_slots, name: "index_time_slots_unique_per_court", if_exists: true
    remove_index :time_slots, column: [ :court_id, :day_of_week, :start_time ], if_exists: true

    add_index :time_slots,
              [ :court_id, :day_of_week, :start_time, :end_time ],
              unique: true,
              where: "effective_on IS NULL",
              name: "index_time_slots_weekly_unique_per_court"

    add_index :time_slots,
              [ :court_id, :effective_on, :start_time, :end_time ],
              unique: true,
              where: "effective_on IS NOT NULL",
              name: "index_time_slots_override_unique_per_court"
  end
end
