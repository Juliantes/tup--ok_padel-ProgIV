class AddCourtSideToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :court_side, :integer
    add_check_constraint :users,
                         "court_side IS NULL OR (court_side = ANY (ARRAY[0, 1]))",
                         name: "users_court_side_range"
  end
end
