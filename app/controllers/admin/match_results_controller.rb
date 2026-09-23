module Admin
  class MatchResultsController < BaseController
    before_action :set_match
    before_action :set_match_result, only: %i[edit update destroy]

    def edit
    end

    def update
      if @match_result.update(match_result_params)
        redirect_to admin_match_path(@match), notice: "Result updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @match_result.destroy!
      redirect_to admin_match_path(@match), notice: "Result deleted."
    end

    private

    def set_match
      @match = Match.find(params[:match_id])
    end

    def set_match_result
      @match_result = @match.match_results.find(params[:id])
    end

    def match_result_params
      params.require(:match_result).permit(:team_a_score, :team_b_score, :winner_team)
    end
  end
end
