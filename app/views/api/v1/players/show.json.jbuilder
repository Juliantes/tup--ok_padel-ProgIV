json.partial! "api/v1/players/player", player: @player

json.star_counts @star_counts

json.reviews @reviews do |review|
  json.partial! "api/v1/players/review", review: review
end
