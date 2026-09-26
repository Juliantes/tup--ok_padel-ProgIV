FactoryBot.define do
  factory :match do
    court
    creator { association :user, :player }
    date { 1.week.from_now.change(hour: 10, min: 0) }
    duration { 90 }
    status { :open }
    level_required { :fifth }
    roster_mode { :pairs }
    join_policy { :auto }

    trait :pairs do
      roster_mode { :pairs }
    end

    trait :individual do
      roster_mode { :individual }
    end

    trait :with_time_slot do
      time_slot { association :time_slot, court: court, day_of_week: date.wday }
    end
  end
end
