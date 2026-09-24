class AddAutoApprovedAtToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :auto_approved_at, :datetime
  end
end
