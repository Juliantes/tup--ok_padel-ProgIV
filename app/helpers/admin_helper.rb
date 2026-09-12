module AdminHelper
  def admin_nav_link(label, path)
    active = current_page?(path) ? "active" : ""
    link_to label, path, class: "nav-link #{active}"
  end
end
