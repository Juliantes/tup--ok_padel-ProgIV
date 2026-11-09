# frozen_string_literal: true

class AddressAutocomplete
  class GeoapifyUnavailable < StandardError; end

  def initialize(geoapify_client: Geoapify::AutocompleteClient.new)
    @geoapify_client = geoapify_client
  end

  def call(query)
    stripped = query.to_s.strip
    return [] if stripped.length < 3

    cached = Address.prefix_search(stripped).to_a
    return cached if cached.any?

    upsert_from_geoapify(stripped)
  rescue Geoapify::AutocompleteClient::ConfigurationError, Geoapify::AutocompleteClient::RequestError
    raise GeoapifyUnavailable, "geoapify_unavailable"
  end

  private

  def upsert_from_geoapify(query)
    rows = @geoapify_client.fetch(query)
    return [] if rows.empty?

    rows.filter_map do |attrs|
      record = Address.find_or_initialize_by(place_id: attrs[:place_id])
      record.assign_attributes(attrs)
      record.save!
      record
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end
end
