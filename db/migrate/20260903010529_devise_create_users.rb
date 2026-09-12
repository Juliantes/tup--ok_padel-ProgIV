# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.string :name, null: false
      t.string :phone, null: false
      t.integer :self_level, null: false
      t.text :bio
      t.boolean :accepts_messages, default: true, null: false

      t.decimal :average_level, precision: 3, scale: 1, default: 0
      t.decimal :average_stars, precision: 3, scale: 2, default: 0
      t.integer :total_reviews, default: 0, null: false
      t.integer :matches_played, default: 0, null: false
      t.integer :matches_cancelled, default: 0, null: false
      t.integer :matches_abandoned, default: 0, null: false

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :phone,                unique: true
  end
end
