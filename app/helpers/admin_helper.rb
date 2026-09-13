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
      [label, key]
    end
  end
end
