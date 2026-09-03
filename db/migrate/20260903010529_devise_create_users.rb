class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Campos de perfil (los que agregamos)
      t.string :name, null: false
      t.string :phone, null: false
      t.integer :self_level, null: false
      t.text :bio
      t.boolean :accepts_messages, default: true, null: false

      ## Campos cacheados para estadísticas de reputación y participación
      ## (se actualizan automáticamente con callbacks)
      ## Para récord competitivo (wins/losses/streaks) ver player_stats
      t.decimal :average_level, precision: 3, scale: 1, default: 0
      t.decimal :average_stars, precision: 3, scale: 2, default: 0
      t.integer :total_reviews, default: 0, null: false
      t.integer :matches_played, default: 0, null: false
      t.integer :matches_cancelled, default: 0, null: false
      t.integer :matches_abandoned, default: 0, null: false

      ## Database authenticatable (Devise)
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable (Devise)
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable (Devise)
      t.datetime :remember_created_at

      ## Trackable (opcional, descomentar si lo usas)
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable (opcional)
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :phone, unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
  end
end