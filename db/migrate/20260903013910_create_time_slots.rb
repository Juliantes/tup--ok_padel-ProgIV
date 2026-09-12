class CreateTimeSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :time_slots do |t|
      t.references :court, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :is_available, default: true, null: false

      t.timestamps
    end

    add_index :time_slots, [ :court_id, :day_of_week, :start_time, :end_time ],
              unique: true,
              name: "index_time_slots_unique_per_court"
  end
end