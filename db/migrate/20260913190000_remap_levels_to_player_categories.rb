class RemapLevelsToPlayerCategories < ActiveRecord::Migration[8.1]
  MATCH_LEVEL_MAP = {
    0 => 8,
    1 => 5,
    2 => 3,
    3 => 0
  }.freeze

  REVIEW_LEVEL_MAP = {
    1 => 8,
    2 => 6,
    3 => 5,
    4 => 3,
    5 => 1
  }.freeze

  def up
    MATCH_LEVEL_MAP.each do |old_value, new_value|
      execute <<~SQL.squish
        UPDATE matches SET level_required = #{new_value} WHERE level_required = #{old_value}
      SQL
    end

    REVIEW_LEVEL_MAP.each do |old_value, new_value|
      execute <<~SQL.squish
        UPDATE reviews SET level_rating = #{new_value} WHERE level_rating = #{old_value}
      SQL
    end
  end

  def down
    reverse_match_map = MATCH_LEVEL_MAP.invert
    reverse_review_map = REVIEW_LEVEL_MAP.invert

    reverse_match_map.each do |old_value, new_value|
      execute <<~SQL.squish
        UPDATE matches SET level_required = #{new_value} WHERE level_required = #{old_value}
      SQL
    end

    reverse_review_map.each do |old_value, new_value|
      execute <<~SQL.squish
        UPDATE reviews SET level_rating = #{new_value} WHERE level_rating = #{old_value}
      SQL
    end
  end
end
