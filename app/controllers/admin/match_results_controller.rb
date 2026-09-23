module Admin
  class MatchResultsController < BaseController
    before_action :set_match
    before_action :set_match_result, only: %i[edit update destroy]

    def edit
      existing = @match_result.match_sets.pluck(:order)
      (1..5).each do |order|
        next if existing.include?(order)

        @match_result.match_sets.build(order: order)
      end
    end

    def update
      if @match_result.update(match_result_params)
        redirect_to admin_match_path(@match), notice: "Result updated."
      else
        edit
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
      @match_result = @match.match_results.includes(:match_sets).find(params[:id])
    end

    def match_result_params
      params.require(:match_result).permit(
        match_sets_attributes: %i[id order team_a_games team_b_games _destroy]
      )
    end
  end
end
