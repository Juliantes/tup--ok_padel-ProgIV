json.id match.id
json.date match.date.iso8601
json.duration match.duration
json.status match.status
json.roster_mode match.roster_mode
json.level_required match.level_required
json.join_policy match.join_policy
json.court do
  json.id match.court.id
  json.name match.court.name
  json.club_id match.court.club_id
end
json.creator do
  json.id match.creator.id
  json.name match.creator.name
end
active_players = match.match_players.reject(&:cancelled?)
json.match_players active_players do |match_player|
  json.partial! "api/v1/matches/match_player", match_player: match_player
end
json.players_count active_players.size
json.max_players MatchPlayer::MAX_PLAYERS

if local_assigns.fetch(:show_details, false)
  if match.time_slot
    json.time_slot do
      json.id match.time_slot.id
      json.day_of_week match.time_slot.day_of_week
      json.start_time match.time_slot.start_time.strftime("%H:%M")
      json.end_time match.time_slot.end_time.strftime("%H:%M")
      json.is_available match.time_slot.is_available
    end
  else
    json.time_slot nil
  end

  json.match_results match.match_results.sort_by { |result| [ result.created_at, result.id ] } do |result|
    json.partial! "api/v1/match_results/match_result", match_result: result
  end
  json.partial! "api/v1/match_results/consensus", consensus: match.consensus_result
end
