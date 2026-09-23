class AddBestOfToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :best_of, :integer, null: false, default: 3
  end
end
