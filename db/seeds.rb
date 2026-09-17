# frozen_string_literal: true

puts "Seeding Ok Padel..."

admin = User.find_or_create_by!(email: "admin@okpadel.local") do |user|
  user.password = "password123"
  user.name = "Admin Ok Padel"
  user.phone = "1100000001"
  user.self_level = 5
  user.bio = "Administrador del sistema"
end
admin.user_roles.find_or_create_by!(role: "admin")

owner = User.find_or_create_by!(email: "owner@okpadel.local") do |user|
  user.password = "password123"
  user.name = "Dueño del Club"
  user.phone = "1100000002"
  user.self_level = 6
  user.bio = "Dueño y gestor del club"
end
owner.user_roles.find_or_create_by!(role: "club_owner")

player = User.find_or_create_by!(email: "player@okpadel.local") do |user|
  user.password = "password123"
  user.name = "Jugador Demo"
  user.phone = "1100000003"
  user.self_level = 4
  user.bio = "Jugador de prueba"
end
player.user_roles.find_or_create_by!(role: "player")

club = Club.find_or_create_by!(name: "Ok Padel Club") do |record|
  record.owner = owner
  record.address = "Av. Siempre Viva 742, Buenos Aires"
  record.phone = "1144556677"
  record.email = "contacto@okpadel.local"
end

courts_data = [
  { name: "Cancha 1", court_type: :indoor, price_per_hour: 8000, description: "Indoor · Césped sintético" },
  { name: "Cancha 2", court_type: :outdoor, price_per_hour: 6000, description: "Outdoor · Cemento" },
  { name: "Cancha 3", court_type: :indoor, price_per_hour: 8500, description: "Indoor · Césped sintético premium" }
]

courts = courts_data.map do |data|
  club.courts.find_or_create_by!(name: data[:name]) do |court|
    court.assign_attributes(data.except(:name))
    court.status = :active
  end
end

courts.each do |court|
  (1..5).each do |day|
    court.time_slots.find_or_create_by!(day_of_week: day, start_time: "10:00", end_time: "11:30") do |slot|
      slot.is_available = true
    end
    court.time_slots.find_or_create_by!(day_of_week: day, start_time: "18:00", end_time: "19:30") do |slot|
      slot.is_available = true
    end
  end
end

sample_court = courts.first
sample_slot = sample_court.time_slots.find_by!(day_of_week: 1, start_time: "10:00")

match = Match.find_or_create_by!(
  court: sample_court,
  creator: player,
  date: Date.current.next_occurring(:monday).change(hour: 10)
) do |record|
  record.time_slot = sample_slot
  record.duration = 90
  record.status = :open
  record.level_required = :fifth
end

extra_players = [
  { email: "player2@okpadel.local", name: "Jugador Demo 2", phone: "1100000004" },
  { email: "player3@okpadel.local", name: "Jugador Demo 3", phone: "1100000005" },
  { email: "player4@okpadel.local", name: "Jugador Demo 4", phone: "1100000006" }
].map do |data|
  User.find_or_create_by!(email: data[:email]) do |user|
    user.password = "password123"
    user.name = data[:name]
    user.phone = data[:phone]
    user.self_level = 4
    user.bio = "Jugador de prueba"
  end.tap { |user| user.user_roles.find_or_create_by!(role: "player") }
end

[
  [ player, :team_a ],
  [ extra_players[0], :team_a ],
  [ extra_players[1], :team_b ],
  [ extra_players[2], :team_b ]
].each do |match_user, team|
  MatchPlayer.find_or_create_by!(match: match, user: match_user) do |record|
    record.status = :confirmed
    record.team = team
  end
end

match.refresh_roster_status!

puts "Done."
puts "  Admin:  admin@okpadel.local / password123"
puts "  Owner:  owner@okpadel.local / password123"
puts "  Player: player@okpadel.local / password123"
puts "  Club:   #{club.name} (#{club.courts.count} courts, #{TimeSlot.count} time slots)"
