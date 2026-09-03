FactoryBot.define do
  factory :message do
    sender { nil }
    receiver { nil }
    match { nil }
    content { "MyText" }
    is_group_chat { false }
    read { false }
    read_at { "2026-09-02 22:40:48" }
  end
end
