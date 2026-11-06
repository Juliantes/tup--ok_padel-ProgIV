json.club do
  json.id @schedule[:club].id
  json.name @schedule[:club].name
  json.address @schedule[:club].address
  json.phone @schedule[:club].phone
end

json.date @schedule[:date].iso8601

json.courts @schedule[:courts] do |court|
  json.id court.id
  json.name court.name
  json.price_per_hour court.price_per_hour.to_f
  json.status court.status
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
end
