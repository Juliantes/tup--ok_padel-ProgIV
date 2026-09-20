json.match do
  json.partial! "api/v1/matches/match", match: @match, show_details: true
end
