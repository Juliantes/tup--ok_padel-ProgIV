json.matches @matches do |match|
  json.partial! "api/v1/matches/match", match: match
end

json.meta do
  json.current_page @pagy.page
  json.per_page @pagy.limit
  json.total_pages @pagy.pages
  json.total_count @pagy.count
end
