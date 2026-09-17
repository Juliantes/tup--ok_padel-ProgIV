json.id court.id
json.name court.name
json.description court.description
json.court_type court.court_type
json.price_per_hour court.price_per_hour.to_f
json.status court.status
json.club do
  json.id court.club.id
  json.name court.club.name
  json.address court.club.address
end
if court.image.attached?
  json.image_url rails_blob_url(court.image)
end
