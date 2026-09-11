FactoryBot.define do
  factory :review do
    reviewer { association :user, :player }
    reviewed_user { association :user, :player }
    match
    level_rating { 4 }
    stars { 5 }
    comment { Faker::Lorem.sentence }
    is_upgradable { true }
  end
end
