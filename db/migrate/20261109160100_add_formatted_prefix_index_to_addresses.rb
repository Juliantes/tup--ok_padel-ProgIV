# frozen_string_literal: true

class AddFormattedPrefixIndexToAddresses < ActiveRecord::Migration[8.1]
  def change
    add_index :addresses, :formatted, opclass: :text_pattern_ops, name: "index_addresses_on_formatted_prefix"
  end
end
