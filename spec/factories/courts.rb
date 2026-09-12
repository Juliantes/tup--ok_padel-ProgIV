FactoryBot.define do
  factory :court do
    club { nil }
    name { "MyString" }
    court_type { 1 }
    price_per_hour { "9.99" }
    status { 1 }
    description { "MyText" }
  end
end
