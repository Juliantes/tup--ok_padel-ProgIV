# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :street, limit: 255
      t.string :housenumber, limit: 64
      t.string :city, limit: 255
      t.string :province, limit: 255
      t.string :postcode, limit: 32
      t.string :country, limit: 255
      t.text :formatted, null: false
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 11, scale: 7
      t.string :place_id, null: false

      t.timestamps
    end

    add_index :addresses, :place_id, unique: true
    add_index :addresses, :city, opclass: :varchar_pattern_ops, name: "index_addresses_on_city_prefix"
    add_index :addresses, :street, opclass: :varchar_pattern_ops, name: "index_addresses_on_street_prefix"
  end
end
