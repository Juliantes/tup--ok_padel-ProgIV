class CreatePlayerStats < ActiveRecord::Migration[8.0]
  def change
    create_table :player_stats do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      # total_matches se deriva de wins + losses en el modelo
      t.integer :wins, default: 0, null: false
      t.integer :losses, default: 0, null: false
      t.decimal :win_rate, precision: 5, scale: 2, default: 0
      t.integer :current_streak, default: 0, null: false
      t.integer :best_streak, default: 0, null: false

      t.timestamps
    end
  end
end