FactoryBot.define do
  factory :match_result do
    match
    reported_by { association :user, :player }
    team_a_score { 6 }
    team_b_score { 4 }
    winner_team { :team_a }

    after(:build) do |result|
      next if result.match.blank? || result.reported_by.blank?

      result.match.save! unless result.match.persisted?
      result.reported_by.save! unless result.reported_by.persisted?
      result.match_id = result.match.id
      result.reported_by_id = result.reported_by.id
      next if result.match.match_players.exists?(user_id: result.reported_by_id)

      result.match.match_players.create!(
        user: result.reported_by,
        status: :confirmed,
        team: :team_a
      )
    end
  end
end
