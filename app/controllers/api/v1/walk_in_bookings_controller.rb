# frozen_string_literal: true

module Api
  module V1
    class WalkInBookingsController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club
      before_action :set_walk_in_match, only: :destroy

      def create
        result = WalkInBookingCreator.new(
          club: @club,
          owner: current_user,
          params: walk_in_params
        ).call

        if result.success?
          @match = result.match
          render :create, status: :created
        elsif result.record
          render_record_errors(result.record)
        else
          render_error(result.message, status: :unprocessable_content)
        end
      end

      def destroy
        unless @match.walk_in?
          return render_error("Not a walk-in booking", status: :unprocessable_content)
        end

        if @match.completed? || @match.reported?
          return render_error("Match cannot be cancelled", status: :unprocessable_content)
        end

        @match.update!(status: :cancelled)
        head :no_content
      end

      private

      def walk_in_params
        params.permit(:court_id, :time_slot_id, :date, :walk_in_guest_name, :walk_in_guest_phone)
      end

      def set_walk_in_match
        @match = Match.joins(:court)
                      .where(courts: { club_id: @club.id })
                      .find(params[:id])
      end
    end
  end
end
