class AddJoinPolicyToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :join_policy, :integer, default: 0, null: false
    add_index :matches, :join_policy
  end
end
