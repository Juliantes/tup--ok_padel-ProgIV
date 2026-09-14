FactoryBot.define do
  factory :match_player do
    match
    user { association :user, :player }
    status { :confirmed }
    team { :team_a }

    trait :pending do
      status { :pending }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :team_b do
      team { :team_b }
    end

    trait :without_team do
      team { nil }
    end
  end
end
