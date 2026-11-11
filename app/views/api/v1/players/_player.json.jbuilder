stat = player.player_stat
aggregate = @review_aggregates&.[](player.id) || {}
wins = stat&.wins.to_i
losses = stat&.losses.to_i

json.id player.id
json.name player.name
json.self_level player.self_level
json.category_label player.category_label
json.court_side player.court_side
json.court_side_label player.court_side_label
json.bio player.bio
json.wins wins
json.losses losses
json.played wins + losses
json.win_rate stat&.win_rate
json.current_streak stat&.current_streak.to_i
json.best_streak stat&.best_streak.to_i
json.average_stars aggregate[:average_stars]
json.reviews_count aggregate[:reviews_count].to_i
