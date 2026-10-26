module Api
  module V1
    class ClubsController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club, only: %i[show update destroy]

      def index
        @clubs = owned_clubs.order(:name)
        render :index
      end

      def show
        render :show
      end

      def create
        @club = owned_clubs.build(club_attributes)
        @club.owner = current_user

        if @club.save
          render :show, status: :created
        else
          render_record_errors(@club)
        end
      end

      def update
        if @club.update(club_attributes)
          render :show
        else
          render_record_errors(@club)
        end
      end

      def destroy
        if @club.destroy
          head :no_content
        else
          render_record_errors(@club)
        end
      end

      private

      def club_attributes
        params.permit(:name, :address, :phone, :email)
      end
    end
  end
end
