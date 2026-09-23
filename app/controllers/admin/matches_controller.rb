module Admin
  class MatchesController < BaseController
    before_action :set_match, only: %i[show edit update force_result mark_played]
    before_action :load_roster_data, only: %i[show edit]

    def index
      scope = Match.includes(:court, :creator, :match_results).order(date: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagy, @matches = pagy(:offset, scope)
    end

    def show
      @match_results = @match.match_results.includes(:reported_by).order(:created_at)
      @consensus = @match.consensus_result
    end

    def force_result
      @match.force_result!(
        admin: current_user,
        **force_result_params.to_h.symbolize_keys
      )
      redirect_to admin_match_path(@match), notice: "Result was forced and the match was closed."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_match_path(@match), alert: e.record.errors.full_messages.to_sentence
    end

    def mark_played
      @match.mark_as_played!
      redirect_to admin_match_path(@match), notice: "Match was marked as played."
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
      params.require(:match).permit(:status, :level_required, :roster_mode)
    end

    def force_result_params
      params.require(:force_result).permit(:team_a_score, :team_b_score, :winner_team)
    end

    def load_roster_data
      enrolled_user_ids = @match.active_match_players.pluck(:user_id)
      @available_users = User.order(:name).where.not(id: enrolled_user_ids)
    end
  end
end
