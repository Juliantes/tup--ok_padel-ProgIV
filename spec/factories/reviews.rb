FactoryBot.define do
  factory :review do
    reviewer { nil }
    reviewed_user { nil }
    match { nil }
    level_rating { 1 }
    stars { 1 }
    comment { "MyText" }
    is_upgradable { false }
  end
end
