FactoryBot.define do
  factory :time_slot do
    court { nil }
    day_of_week { 1 }
    start_time { "2026-09-02 22:39:10" }
    end_time { "2026-09-02 22:39:10" }
    is_available { false }
  end
end
