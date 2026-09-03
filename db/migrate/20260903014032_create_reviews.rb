class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewed_user, null: false, foreign_key: { to_table: :users }
      t.references :match, null: false, foreign_key: true
      t.integer :level_rating, null: false
      t.integer :stars, null: false
      t.text :comment
      t.boolean :is_upgradable, default: true, null: false

      t.timestamps
    end

    # Solo una review por reviewer-reviewed-match
    add_index :reviews, [:reviewer_id, :reviewed_user_id, :match_id], 
      unique: true, name: "index_reviews_unique_per_match"
  end
end