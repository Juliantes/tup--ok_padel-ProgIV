FactoryBot.define do
  factory :match_player do
    match
    user { association :user, :player }
    status { :confirmed }
    team { :team_a }
  end
end
