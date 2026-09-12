FactoryBot.define do
  factory :message do
    sender { association :user, :player }
    receiver { association :user, :player }
    content { Faker::Lorem.sentence }
    is_group_chat { false }
    read { false }
  end
end
