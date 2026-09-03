FactoryBot.define do
  factory :match do
    court { nil }
    creator { nil }
    time_slot { nil }
    date { "2026-09-02 22:39:30" }
    duration { 1 }
    status { 1 }
    level_required { 1 }
  end
end
