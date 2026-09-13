module Admin
  class DashboardController < BaseController
    def index
      @clubs_count = Club.count
      @courts_count = Court.count
      @users_count = User.count
      @matches_count = Match.count
      @recent_matches = Match.includes(:court, :creator).order(date: :desc).limit(5)
    end
  end
end
