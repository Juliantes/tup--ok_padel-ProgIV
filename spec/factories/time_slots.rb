FactoryBot.define do
  factory :time_slot do
    court
    day_of_week { 1 }
    start_time { Time.zone.parse("10:00") }
    end_time { Time.zone.parse("11:30") }
    is_available { true }
  end
end
