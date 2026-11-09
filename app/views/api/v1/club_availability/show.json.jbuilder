json.club do
  json.id @schedule[:club].id
  json.name @schedule[:club].name
  json.address @schedule[:club].address
  json.country @schedule[:club].country
  json.province @schedule[:club].province
  json.city @schedule[:club].city
  json.lat @schedule[:club].lat&.to_f
  json.lng @schedule[:club].lng&.to_f
  json.phone @schedule[:club].phone
  json.card_theme @schedule[:club].card_theme
end

json.date @schedule[:date].iso8601

json.courts @schedule[:courts] do |court|
  json.id court.id
  json.name court.name
  json.price_per_hour court.price_per_hour.to_f
  json.status court.status
  json.color court.color
end

json.rows @schedule[:rows] do |row|
  json.start_time row[:start_time]
  json.end_time row[:end_time]
end

json.cells @schedule[:cells] do |cell|
  json.court_id cell.court_id
  json.start_time cell.start_time
  json.state cell.state
  json.time_slot_id cell.time_slot_id
  json.end_time cell.end_time
  if cell.state == "booked" && cell.match_id.present? && !cell.player_booking && !cell.walk_in
    json.match_id cell.match_id
  end
end
