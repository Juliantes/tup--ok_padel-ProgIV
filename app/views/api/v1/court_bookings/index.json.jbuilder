json.court_bookings @court_bookings do |match|
  json.id match.id
  json.date match.date.iso8601
  json.duration match.duration
  json.status match.status
  json.estimated_price (match.court.price_per_hour * match.duration / 60.0).round(2).to_f
  json.cancellable match.leavable? && !match.cancelled? && !match.completed? && !match.reported?
  json.court do
    json.id match.court.id
    json.name match.court.name
    json.price_per_hour match.court.price_per_hour.to_f
  end
  json.club do
    json.id match.court.club.id
    json.name match.court.club.name
    json.address match.court.club.address
  end
  if match.time_slot
    json.time_slot do
      json.id match.time_slot.id
      json.start_time match.time_slot.start_time.strftime("%H:%M")
      json.end_time match.time_slot.end_time.strftime("%H:%M")
    end
  end
end
