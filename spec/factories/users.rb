FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { Faker::Name.name }
    sequence(:phone) { |n| "11#{format('%08d', n)}" }
    self_level { rand(User::SELF_LEVEL_RANGE) }
    bio { Faker::Lorem.paragraph(sentence_count: 2) }

    trait :admin do
      after(:create) do |user|
        create(:user_role, user: user, role: "admin")
      end
    end

    trait :club_owner do
      after(:create) do |user|
        create(:user_role, user: user, role: "club_owner")
      end
    end

    trait :player do
      after(:create) do |user|
        create(:user_role, user: user, role: "player")
      end
    end
  end
end
