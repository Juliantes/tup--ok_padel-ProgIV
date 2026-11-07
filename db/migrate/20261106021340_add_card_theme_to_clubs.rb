class AddCardThemeToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :card_theme, :integer, null: false, default: 0
  end
end
