# frozen_string_literal: true

# Ejemplo ilustrativo de búsqueda híbrida: caché local (LIKE prefijo) + fallback Geoapify.
# En producción ver: app/services/address_autocomplete.rb y app/models/address.rb

PREFIX_QUERY = "La Plat"

# 1) Buscar en base local con comodín % solo al final (aprovecha índices prefix)
local_matches = Address
  .where("city LIKE :p OR street LIKE :p OR formatted LIKE :p", p: "#{PREFIX_QUERY}%")
  .where(country: "Argentina")
  .limit(5)

if local_matches.any?
  puts "Cache hit: #{local_matches.size} direcciones"
  local_matches.each { |row| puts row.formatted }
else
  # 2) Fallback: Geoapify (solo Argentina)
  client = Geoapify::AutocompleteClient.new(api_key: ENV.fetch("GEOAPIFY_API_KEY", ""))
  attrs_list = client.fetch(PREFIX_QUERY)

  saved = attrs_list.filter_map do |attrs|
    record = Address.find_or_initialize_by(place_id: attrs[:place_id])
    record.assign_attributes(attrs)
    record.save!
    record
  end

  puts "Geoapify + cache: #{saved.size} direcciones nuevas"
end
