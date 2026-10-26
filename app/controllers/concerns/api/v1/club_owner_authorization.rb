module Api
  module V1
    module ClubOwnerAuthorization
      extend ActiveSupport::Concern

      included do
        before_action :require_club_owner!
      end

      private

      def require_club_owner!
        return if current_user&.club_owner?

        render_error("Forbidden", status: :forbidden)
      end

      def owned_clubs
        current_user.owned_clubs
      end

      def set_owned_club
        @club = owned_clubs.find(params[:club_id] || params[:id])
      end
    end
  end
end
