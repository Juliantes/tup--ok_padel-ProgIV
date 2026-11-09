# frozen_string_literal: true

require "net/http"
require "json"

module Geoapify
  class AutocompleteClient
    class RequestError < StandardError; end
    class ConfigurationError < StandardError; end

    ENDPOINT = "https://api.geoapify.com/v1/geocode/autocomplete"
    CABA_PROVINCE = "Ciudad Autónoma de Buenos Aires"
    LIMIT = 5

    def initialize(api_key: ENV["GEOAPIFY_API_KEY"])
      @api_key = api_key.to_s.strip
    end

    def fetch(text)
      raise ConfigurationError, "GEOAPIFY_API_KEY is not configured" if @api_key.blank?

      query = text.to_s.strip
      raise RequestError, "query too short" if query.length < 3

      uri = URI(ENDPOINT)
      uri.query = URI.encode_www_form(
        text: query,
        lang: "es",
        limit: LIMIT,
        filter: "countrycode:ar",
        apiKey: @api_key
      )

      response = Net::HTTP.get_response(uri)
      raise RequestError, "geoapify request failed" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      features = body["features"] || []
      features.filter_map { |feature| build_attributes(feature) }
    rescue JSON::ParserError
      raise RequestError, "invalid geoapify response"
    end

    private

    def build_attributes(feature)
      props = feature["properties"] || {}
      place_id = props["place_id"].to_s.strip
      formatted = props["formatted"].to_s.strip
      return nil if place_id.blank? || formatted.blank?

      lat = props["lat"] || feature.dig("geometry", "coordinates", 1)
      lng = props["lon"] || feature.dig("geometry", "coordinates", 0)
      return nil if lat.nil? || lng.nil?

      province = props["state"].to_s.strip
      province = CABA_PROVINCE if props["iso3166_2"] == "AR-C"

      city = props["city"].presence || props["county"].presence || props["district"].presence
      city = city.to_s.strip

      {
        place_id: place_id,
        formatted: formatted,
        street: props["street"].to_s.strip.presence,
        housenumber: props["housenumber"].to_s.strip.presence,
        city: city.presence,
        province: province.presence,
        postcode: props["postcode"].to_s.strip.presence,
        country: props["country"].to_s.strip.presence || "Argentina",
        lat: BigDecimal(lat.to_s),
        lng: BigDecimal(lng.to_s)
      }
    end
  end
end
