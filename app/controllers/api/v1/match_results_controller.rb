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
        sets = sets_params
        if sets.blank?
          return render_error("sets is required", status: :unprocessable_content)
        end

        @match.report_result!(reporter: current_user, sets: sets)
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
        @match = Match.includes(:court, :creator, :time_slot, :match_players, match_results: [ :reported_by, :match_sets ]).find(@match.id)
        @results = ordered_results
      end

      def ordered_results
        @match.match_results.includes(:reported_by, :match_sets).order(:created_at, :id)
      end

      def sets_params
        raw = params.permit(sets: %i[team_a_games team_b_games])[:sets]
        return [] if raw.blank?

        raw.filter_map do |set|
          next if set[:team_a_games].blank? && set[:team_b_games].blank?

          set.to_h.symbolize_keys
        end
      end
    end
  end
end
