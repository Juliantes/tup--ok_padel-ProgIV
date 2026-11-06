json.court_booking do
  json.id @match.id
  json.court_id @match.court_id
  json.time_slot_id @match.time_slot_id
  json.date @match.date.iso8601
  json.duration @match.duration
  json.status @match.status
  json.player_booking @match.player_booking
  json.estimated_price (@match.court.price_per_hour * @match.duration / 60.0).round(2).to_f
  json.cancellable @match.leavable?
end
