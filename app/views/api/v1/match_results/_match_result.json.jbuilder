json.id match_result.id
json.sets match_result.match_sets.sort_by(&:order) do |set|
  json.order set.order
  json.team_a_games set.team_a_games
  json.team_b_games set.team_b_games
end
json.winner_team match_result.winner_team&.to_s
json.reported_by do
  json.id match_result.reported_by.id
  json.name match_result.reported_by.name
end
json.created_at match_result.created_at.iso8601
