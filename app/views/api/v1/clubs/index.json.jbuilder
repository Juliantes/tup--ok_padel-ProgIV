json.clubs @clubs do |club|
  json.partial! "api/v1/clubs/club", club: club
end
