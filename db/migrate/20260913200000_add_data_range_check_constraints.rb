# frozen_string_literal: true

class AddDataRangeCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :courts,
                         "price_per_hour > 0 AND price_per_hour <= 99999999.99",
                         name: "courts_price_per_hour_range"

    add_check_constraint :users,
                         "self_level >= 1 AND self_level <= 8",
                         name: "users_self_level_range"
  end
end
