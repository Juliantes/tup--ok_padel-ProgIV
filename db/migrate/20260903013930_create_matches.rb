class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :court, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :time_slot, foreign_key: true
      t.datetime :date, null: false
      t.integer :duration, default: 90, null: false
      t.integer :status, default: 0, null: false
      t.integer :level_required, default: 0, null: false

      t.timestamps
    end

    # Índices para búsquedas rápidas
    add_index :matches, [:date, :court_id]
    add_index :matches, :status
  end
end
