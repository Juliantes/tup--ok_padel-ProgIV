class AddStatusDateIndexToMatches < ActiveRecord::Migration[8.1]
  def change
    add_index :matches, %i[status date]
  end
end
