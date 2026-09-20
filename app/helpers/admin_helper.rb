module AdminHelper
  def admin_nav_link(label, path)
    active = current_page?(path) ? "active" : ""
    link_to label, path, class: "nav-link #{active}"
  end

  def category_label(value)
    return "Libre" if value.blank? || value.to_i.zero?

    Match.category_label(value) || "Libre"
  end

  def match_level_required_options
    Match.level_requireds.keys.map do |key|
      value = Match.level_requireds[key]
      label = value.zero? ? "Libre" : Match.category_label(value)
      [ label, key ]
    end
  end

  def match_roster_mode_options
    [
      [ "Parejas (2 de 2)", "pairs" ],
      [ "Jugadores sueltos (4)", "individual" ]
    ]
  end

  def roster_mode_label(mode)
    match_roster_mode_options.find { |_, key| key == mode }&.first || mode.to_s.humanize
  end
end
