# frozen_string_literal: true

module Api
  module V1
    module ClubOwnerAuthorization
      extend ActiveSupport::Concern

      private

      def require_club_owner!
        return if current_user.club_owner?

        render_error("club owner role required", status: :forbidden)
      end

      def set_owned_club
        @club = current_user.owned_clubs.find(params[:club_id])
      end

      def set_owned_court
        set_owned_club
        return if performed?

        @court = @club.courts.find(params[:id])
      end
    end
  end
end
