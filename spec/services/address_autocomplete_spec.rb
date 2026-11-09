# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddressAutocomplete do
  let(:client) { instance_double(Geoapify::AutocompleteClient) }
  subject(:service) { described_class.new(geoapify_client: client) }

  describe "#call" do
    it "returns cached rows without calling Geoapify" do
      create(:address, city: "La Plata", formatted: "Av 7, La Plata")

      expect(client).not_to receive(:fetch)

      results = service.call("La Plat")
      expect(results.size).to eq(1)
      expect(results.first.city).to eq("La Plata")
    end

    it "persists Geoapify rows on cache miss" do
      expect(client).to receive(:fetch).with("Quilmes Centro").and_return(
        [
          {
            place_id: "geo-new-1",
            formatted: "Av Mitre 100, Quilmes, Argentina",
            street: "Av Mitre",
            housenumber: "100",
            city: "Quilmes",
            province: "Buenos Aires",
            postcode: "1878",
            country: "Argentina",
            lat: BigDecimal("-34.7200"),
            lng: BigDecimal("-58.2540")
          }
        ]
      )

      results = service.call("Quilmes Centro")
      expect(results.size).to eq(1)
      expect(Address.find_by(place_id: "geo-new-1")).to be_present
    end

    it "returns empty for short queries" do
      expect(client).not_to receive(:fetch)
      expect(service.call("ab")).to eq([])
    end

    it "raises when Geoapify is unavailable on cache miss" do
      allow(client).to receive(:fetch).and_raise(Geoapify::AutocompleteClient::ConfigurationError)

      expect { service.call("Nueva Direccion") }.to raise_error(AddressAutocomplete::GeoapifyUnavailable)
    end
  end
end
