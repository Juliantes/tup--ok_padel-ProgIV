FactoryBot.define do
  factory :match_result do
    match
    reported_by { association :user, :player }
    forced_by_admin { false }

    transient do
      result_sets { [ { team_a_games: 6, team_b_games: 4 }, { team_a_games: 6, team_b_games: 4 } ] }
    end

    after(:build) do |result, evaluator|
      next if result.match.blank? || result.reported_by.blank?

      result.match.save! unless result.match.persisted?
      result.reported_by.save! unless result.reported_by.persisted?
      result.match_id = result.match.id
      result.reported_by_id = result.reported_by.id
      unless result.match.match_players.exists?(user_id: result.reported_by_id)
        result.match.match_players.create!(
          user: result.reported_by,
          status: :confirmed,
          team: :team_a
        )
      end

      evaluator.result_sets.each_with_index do |set, idx|
        result.match_sets.build(order: idx + 1, **set)
      end
    end
  end
end
