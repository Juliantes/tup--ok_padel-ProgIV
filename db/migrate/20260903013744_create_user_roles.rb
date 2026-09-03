class CreateUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false

      t.timestamps
    end

    # Índice único: un usuario no puede tener el mismo rol dos veces
    add_index :user_roles, [:user_id, :role], unique: true
  end
end