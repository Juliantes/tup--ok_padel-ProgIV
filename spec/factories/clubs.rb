FactoryBot.define do
  factory :club do
    owner { association :user, :club_owner }
    name { "#{Faker::Company.name} Padel" }
    address { Faker::Address.full_address }
    sequence(:phone) { |n| "11#{format('%08d', n)}" }
    email { Faker::Internet.email }
  end
end
