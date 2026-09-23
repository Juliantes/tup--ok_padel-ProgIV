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
      @match_results = @match.match_results.includes(:reported_by, :match_sets).order(:created_at)
      @consensus = @match.consensus_result
    end

    def force_result
      sets = force_result_sets
      if sets.empty?
        return redirect_to admin_match_path(@match), alert: "At least one set is required."
      end

      @match.force_result!(admin: current_user, sets: sets)
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

    def force_result_sets
      raw = params.fetch(:force_result, {}).permit(sets: %i[team_a_games team_b_games])[:sets] || []
      raw.filter_map do |set|
        next if set[:team_a_games].blank? && set[:team_b_games].blank?

        set.to_h.symbolize_keys
      end
    end

    def load_roster_data
      enrolled_user_ids = @match.active_match_players.pluck(:user_id)
      @available_users = User.order(:name).where.not(id: enrolled_user_ids)
    end
  end
end
