# frozen_string_literal: true

class RemoveStatusAndApprovedByFromMatchResults < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :match_results, column: :approved_by_id
    remove_column :match_results, :status, :integer
    remove_column :match_results, :approved_by_id, :bigint
  end

  def down
    add_column :match_results, :status, :integer, null: false, default: 0
    add_reference :match_results, :approved_by, foreign_key: { to_table: :users }
  end
end
