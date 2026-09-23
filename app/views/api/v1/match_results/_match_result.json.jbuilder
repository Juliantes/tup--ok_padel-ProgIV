json.id match_result.id
json.team_a_score match_result.team_a_score
json.team_b_score match_result.team_b_score
json.winner_team match_result.winner_team
json.reported_by do
  json.id match_result.reported_by.id
  json.name match_result.reported_by.name
end
json.created_at match_result.created_at.iso8601
