module Api
  module V1
    class MatchesController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[index show]

      def index
        scope = Match.where(status: %i[open full])
        scope = apply_list_filters(scope)
        scope = scope.includes(:court, :creator, match_players: :user).order(date: :asc)
        @pagy, @matches = pagy(:offset, scope, limit: api_per_page)
        render :index
      end

      def show
        @match = load_match_for_detail.find(params[:id])
        render :show
      end

      def create
        @match = Match.new(create_params.except(:auto_join))
        @match.creator = current_user

        ActiveRecord::Base.transaction do
          @match.save!
          enroll_creator! if auto_join?
        end

        @match = load_match_for_detail.find(@match.id)
        render :create, status: :created
      end

      def join
        @match = Match.find(params[:id])
        team_attrs = join_team_attributes(@match)
        return if performed?

        MatchPlayer.enroll(match: @match, user: current_user, **team_attrs)
        @match = load_match_for_detail.find(@match.id)
        render :join
      end

      def leave
        @match = Match.find(params[:id])
        match_player = @match.match_players.find_by(user_id: current_user.id)
        raise ActiveRecord::RecordNotFound if match_player.nil? || match_player.cancelled?

        if @match.creator_id == current_user.id && (@match.confirmed? || @match.completed?)
          return render_error("Creator cannot leave a confirmed or completed match", status: :unprocessable_content)
        end

        match_player.update!(status: :cancelled)
        @match.cancel_if_creator_left_empty_roster!(current_user)
        @match = load_match_for_detail.find(@match.id)
        render :leave
      end

      def played
        @match = Match.find(params[:id])
        unless @match.active_match_players.exists?(user_id: current_user.id)
          return render_error("You are not an active player of this match", status: :unprocessable_content)
        end

        if @match.completed? && @match.consensus?
          return render_error("Match is already completed with a consensus result", status: :unprocessable_content)
        end

        @match.mark_as_played!
        @match = load_match_for_detail.find(@match.id)
        render :show
      end

      def mine
        enrolled_ids = MatchPlayer.active.where(user_id: current_user.id).select(:match_id)
        scope = Match.where(creator_id: current_user.id).or(Match.where(id: enrolled_ids))
        scope = apply_status_filter(scope)
        scope = apply_court_filter(scope)
        scope = apply_date_filter(scope)
        scope = scope.includes(:court, :creator, match_players: :user).order(date: :asc)
        @pagy, @matches = pagy(:offset, scope, limit: api_per_page)
        render :index
      end

      private

      def load_match_for_detail
        Match.includes(:court, :creator, :time_slot, match_players: :user, match_results: :reported_by)
      end

      def create_params
        params.permit(:court_id, :time_slot_id, :date, :duration, :roster_mode, :level_required, :auto_join)
      end

      def auto_join?
        ActiveModel::Type::Boolean.new.cast(create_params.fetch(:auto_join, true))
      end

      def enroll_creator!
        MatchPlayer.enroll(match: @match, user: current_user, team: :team_a)
      end

      def join_team_attributes(match)
        team = params[:team]

        if match.roster_mode_pairs?
          if team.blank?
            render_error("Team is required in pairs mode", status: :unprocessable_content)
            return nil
          end

          { team: team }
        elsif team.present?
          { team: team }
        else
          {}
        end
      end

      def apply_list_filters(scope)
        scope = apply_status_filter(scope, allowed: Match.statuses.keys & %w[open full])
        apply_court_filter(apply_date_filter(scope))
      end

      def apply_status_filter(scope, allowed: Match.statuses.keys)
        status = params[:status]
        return scope if status.blank?
        return scope.where(status: status) if allowed.include?(status)

        scope.none
      end

      def apply_court_filter(scope)
        return scope if params[:court_id].blank?

        scope.where(court_id: params[:court_id])
      end

      def apply_date_filter(scope)
        return scope if params[:date].blank?

        day = Date.iso8601(params[:date])
        scope.where(date: day.all_day)
      rescue Date::Error
        scope.none
      end

      def api_per_page
        value = params.fetch(:per_page, 20).to_i
        value = 20 if value < 1
        [ value, 50 ].min
      end
    end
  end
end
