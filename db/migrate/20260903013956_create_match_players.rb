class CreateMatchPlayers < ActiveRecord::Migration[8.0]
  def change
    create_table :match_players do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :team
      t.integer :status, default: 0, null: false
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :joined_at, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :cancelled_at

      t.timestamps
    end

    # Un jugador no puede inscribirse dos veces al mismo partido
    add_index :match_players, [:match_id, :user_id], unique: true
  end
end