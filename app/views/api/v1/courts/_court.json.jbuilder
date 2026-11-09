json.id court.id
json.name court.name
json.description court.description
json.court_type court.court_type
json.price_per_hour court.price_per_hour.to_f
json.status court.status
json.color court.color
json.club do
  json.id court.club.id
  json.name court.club.name
  json.address court.club.address
  json.country court.club.country
  json.province court.club.province
  json.city court.club.city
  json.card_theme court.club.card_theme
end
if court.image.attached?
  json.image_url rails_blob_url(court.image)
end
