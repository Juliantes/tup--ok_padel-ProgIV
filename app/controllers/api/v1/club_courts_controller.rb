module Api
  module V1
    class ClubCourtsController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club
      before_action :set_court, only: %i[show update destroy]

      def index
        @courts = @club.courts.order(:name)
        render :index
      end

      def show
        render :show
      end

      def create
        @court = @club.courts.build(court_attributes)

        if @court.save
          render :show, status: :created
        else
          render_record_errors(@court)
        end
      end

      def update
        if @court.update(court_attributes)
          render :show
        else
          render_record_errors(@court)
        end
      end

      def destroy
        if @court.destroy
          head :no_content
        else
          render_record_errors(@court)
        end
      end

      private

      def set_court
        @court = @club.courts.find(params[:id])
      end

      def court_attributes
        params.permit(:name, :court_type, :price_per_hour, :description, :status)
      end
    end
  end
end
