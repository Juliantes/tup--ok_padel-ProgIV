module Api
  module V1
    class PlayersController < BaseController
      include PlayerAuthorization

      def index
        return if invalid_page_param? || invalid_per_page_param?

        scope = players_scope.includes(:player_stat).order(:name)
        scope = apply_name_filter(scope)
        @pagy, @players = pagy(:offset, scope, limit: api_per_page)
        load_review_aggregates_for(@players)
        render :index
      end

      def show
        @player = players_scope.includes(:player_stat).find(params[:id])
        load_review_aggregates_for([ @player ])
        @star_counts = star_counts_for(@player.id)
        @reviews = Review.where(reviewed_user_id: @player.id)
                         .includes(:reviewer)
                         .order(created_at: :desc)
        render :show
      end

      private

      def players_scope
        User.joins(:user_roles).where(user_roles: { role: "player" }).distinct
      end

      def apply_name_filter(scope)
        term = params[:q].to_s.strip
        return scope if term.blank?

        pattern = "%#{User.sanitize_sql_like(term)}%"
        scope.where("users.name ILIKE ?", pattern)
      end

      def load_review_aggregates_for(players)
        ids = players.map(&:id)
        @review_aggregates = if ids.empty?
          {}
        else
          rows = Review.where(reviewed_user_id: ids)
                       .group(:reviewed_user_id)
                       .pluck(
                         :reviewed_user_id,
                         Arel.sql("COUNT(*)"),
                         Arel.sql("AVG(stars)")
                       )
          rows.each_with_object({}) do |(user_id, count, average), hash|
            hash[user_id] = {
              reviews_count: count,
              average_stars: average.nil? ? nil : average.to_f.round(2)
            }
          end
        end
      end

      def star_counts_for(user_id)
        counts = Review.where(reviewed_user_id: user_id).group(:stars).count
        (1..5).index_with { |stars| counts[stars] || 0 }
      end

      def invalid_page_param?
        return false if params[:page].blank?
        return false if params[:page].to_s.match?(/\A\d+\z/)

        render_error("invalid page", status: :bad_request)
        true
      end

      def invalid_per_page_param?
        return false if params[:per_page].blank?
        return false if params[:per_page].to_s.match?(/\A\d+\z/)

        render_error("invalid per_page", status: :bad_request)
        true
      end

      def api_per_page
        value = params.fetch(:per_page, 20).to_i
        value = 20 if value < 1
        [ value, 50 ].min
      end
    end
  end
end
