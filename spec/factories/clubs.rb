FactoryBot.define do
  factory :club do
    owner { association :user, :club_owner }
    name { "#{Faker::Company.name} Padel" }
    address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.cell_phone }
    email { Faker::Internet.email }
  end
end
