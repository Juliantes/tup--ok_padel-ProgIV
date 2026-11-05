json.match do
  json.id @match.id
  json.court_id @match.court_id
  json.time_slot_id @match.time_slot_id
  json.date @match.date.to_date.iso8601
  json.status @match.status
  json.walk_in @match.walk_in
  json.walk_in_guest_name @match.walk_in_guest_name
  json.walk_in_guest_phone @match.walk_in_guest_phone
end
