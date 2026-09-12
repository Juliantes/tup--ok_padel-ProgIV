# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, foreign_key: { to_table: :users }
      t.references :match, foreign_key: true
      t.text :content, null: false
      t.boolean :is_group_chat, null: false, default: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end
  end
end
