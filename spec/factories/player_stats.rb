FactoryBot.define do
  factory :player_stat do
    user { nil }
    wins { 1 }
    losses { 1 }
    win_rate { "9.99" }
    current_streak { 1 }
    best_streak { 1 }
  end
end
