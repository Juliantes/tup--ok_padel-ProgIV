class CreateCourts < ActiveRecord::Migration[8.0]
  def change
    create_table :courts do |t|
      t.references :club, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :court_type, default: 0, null: false
      t.decimal :price_per_hour, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      t.text :description

      t.timestamps
    end

    add_index :courts, [ :club_id, :name ], unique: true
  end
end