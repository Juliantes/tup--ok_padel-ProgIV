json.id match_player.id
json.user_id match_player.user_id
json.team match_player.team
json.status match_player.status
json.joined_at match_player.joined_at&.iso8601
json.user do
  json.id match_player.user.id
  json.name match_player.user.name
end
