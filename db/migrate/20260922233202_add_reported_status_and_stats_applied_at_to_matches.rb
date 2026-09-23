# frozen_string_literal: true

class AddReportedStatusAndStatsAppliedAtToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :stats_applied_at, :datetime
    # Integer enums are a Ruby mapping, not a PostgreSQL type.
    # `reported: 5` is added on Match, after the existing values.
  end
end
