json.players @players do |player|
  json.partial! "api/v1/players/player", player: player
end

json.meta do
  json.current_page @pagy.page
  json.per_page @pagy.limit
  json.total_pages @pagy.pages
  json.total_count @pagy.count
end
