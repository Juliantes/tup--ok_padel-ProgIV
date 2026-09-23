FactoryBot.define do
  factory :match_set do
    match_result
    order { 1 }
    team_a_games { 6 }
    team_b_games { 4 }
  end
end
