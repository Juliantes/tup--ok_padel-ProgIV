module Api
  module V1
    class MatchResultsController < BaseController
      skip_before_action :authenticate_api_user!, only: :index
      before_action :set_match

      def index
        @results = ordered_results
        render :index
      end

      def create
        @match.report_result!(
          reporter: current_user,
          team_a_score: result_params[:team_a_score],
          team_b_score: result_params[:team_b_score],
          winner_team: result_params[:winner_team].presence
        )
        load_detail!
        render :create, status: :created
      end

      def destroy
        result = @match.match_results.find(params[:id])
        if result.reported_by_id != current_user.id
          return render_error("You can only delete your own result", status: :forbidden)
        end

        result.destroy!
        load_detail!
        render :destroy
      end

      private

      def set_match
        @match = Match.find(params[:match_id])
      end

      def load_detail!
        @match = Match.includes(:court, :creator, :time_slot, :match_players, match_results: :reported_by).find(@match.id)
        @results = ordered_results
      end

      def ordered_results
        @match.match_results.includes(:reported_by).order(:created_at, :id)
      end

      def result_params
        params.permit(:team_a_score, :team_b_score, :winner_team)
      end
    end
  end
end
