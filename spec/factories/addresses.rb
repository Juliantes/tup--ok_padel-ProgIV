# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    sequence(:place_id) { |n| "geoapify-place-#{n}" }
    formatted { "Avenida 7 1234, La Plata, Argentina" }
    street { "Avenida 7" }
    housenumber { "1234" }
    city { "La Plata" }
    province { "Buenos Aires" }
    postcode { "1900" }
    country { "Argentina" }
    lat { BigDecimal("-34.9215") }
    lng { BigDecimal("-57.9545") }
  end
end
