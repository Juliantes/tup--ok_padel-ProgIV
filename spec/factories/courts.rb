FactoryBot.define do
  factory :court do
    club
    sequence(:name) { |n| "Cancha #{n}" }
    court_type { :indoor }
    color { 0 }
    price_per_hour { rand(5_000..10_000) }
    status { :active }
    description { Faker::Lorem.sentence }
  end
end
