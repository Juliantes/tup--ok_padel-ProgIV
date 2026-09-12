FactoryBot.define do
  factory :match_player do
    match { nil }
    user { nil }
    team { 1 }
    status { 1 }
    approved_by { nil }
    joined_at { "2026-09-02 22:39:57" }
    cancelled_at { "2026-09-02 22:39:57" }
  end
end
