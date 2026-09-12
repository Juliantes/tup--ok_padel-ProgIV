class CreateClubs < ActiveRecord::Migration[8.0]
  def change
    create_table :clubs do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.string :phone, null: false
      t.string :email
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end