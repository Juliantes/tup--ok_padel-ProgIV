class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, foreign_key: { to_table: :users }
      t.references :match, foreign_key: true
      t.text :content, null: false
      t.boolean :is_group_chat, default: false, null: false
      t.boolean :read, default: false, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :messages, [ :sender_id, :receiver_id ]
  end
end