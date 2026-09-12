module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      return if current_user&.admin?

      redirect_to root_path, alert: "You do not have permission to access the back office."
    end
  end
end
