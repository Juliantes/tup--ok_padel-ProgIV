FactoryBot.define do
  factory :match_result do
    match
    reported_by { association :user, :player }
    team_a_score { 6 }
    team_b_score { 4 }
    winner_team { :team_a }
    status { :pending }
  end
end
