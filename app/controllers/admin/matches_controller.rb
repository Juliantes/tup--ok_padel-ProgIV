module Admin
  class MatchesController < BaseController
    before_action :set_match, only: %i[show edit update]
    before_action :load_roster_data, only: %i[show edit]

    def index
      scope = Match.includes(:court, :creator).order(date: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagy, @matches = pagy(:offset, scope)
    end

    def show
    end

    def edit
    end

    def update
      if @match.update(match_params)
        redirect_to admin_match_path(@match), notice: "Match was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_match
      @match = Match.find(params[:id])
    end

    def match_params
      params.require(:match).permit(:status, :level_required)
    end

    def load_roster_data
      enrolled_user_ids = @match.match_players.pluck(:user_id)
      @available_users = User.order(:name).where.not(id: enrolled_user_ids)
    end
  end
end
