consensus = local_assigns.fetch(:consensus)
if consensus
  json.consensus do
    json.votes consensus[:votes]
    json.total consensus[:total]
    json.signature consensus[:signature]
    json.sets consensus[:sets].sort_by(&:order) do |set|
      json.order set.order
      json.team_a_games set.team_a_games
      json.team_b_games set.team_b_games
    end
  end
else
  json.consensus nil
end
