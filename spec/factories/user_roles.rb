FactoryBot.define do
  factory :user_role do
    user
    role { "player" }
  end
end
