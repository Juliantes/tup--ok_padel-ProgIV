FactoryBot.define do
  factory :match_result do
    match { nil }
    team_a_score { 1 }
    team_b_score { 1 }
    winner_team { 1 }
    reported_by { nil }
    approved_by { nil }
    approved_at { "2026-09-02 22:40:17" }
    status { 1 }
  end
end
