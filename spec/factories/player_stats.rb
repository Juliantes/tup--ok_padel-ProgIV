FactoryBot.define do
  factory :player_stat do
    user
    wins { 0 }
    losses { 0 }
    win_rate { 0.0 }
    current_streak { 0 }
    best_streak { 0 }
  end
end
