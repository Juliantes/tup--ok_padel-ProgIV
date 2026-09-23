json.match do
  json.partial! "api/v1/matches/match", match: @match, show_details: true
end
json.results @results do |match_result|
  json.partial! "api/v1/match_results/match_result", match_result: match_result
end
json.consensus @match.consensus_result
