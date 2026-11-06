# frozen_string_literal: true

module Api
  module V1
    class CourtBookingsController < BaseController
      include PlayerAuthorization

      before_action :set_court_booking, only: :destroy

      def index
        @court_bookings = Match.player_bookings
                               .where(creator_id: current_user.id)
                               .includes(:time_slot, court: :club)
                               .order(date: :desc)
        render :index
      end

      def create
        result = CourtBookingCreator.new(player: current_user, params: booking_params).call

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
        unless @match.player_booking?
          return render_error("Not a court booking", status: :unprocessable_content)
        end

        if @match.cancelled?
          return render_error("Booking is already cancelled", status: :unprocessable_content)
        end

        if @match.completed? || @match.reported?
          return render_error("Booking cannot be cancelled", status: :unprocessable_content)
        end

        unless @match.leavable?
          return render_error("too late to cancel", status: :unprocessable_content)
        end

        @match.update!(status: :cancelled)
        head :no_content
      end

      private

      def booking_params
        params.permit(:club_id, :court_id, :time_slot_id, :date)
      end

      def set_court_booking
        @match = Match.player_bookings.find_by!(id: params[:id], creator_id: current_user.id)
      end
    end
  end
end
