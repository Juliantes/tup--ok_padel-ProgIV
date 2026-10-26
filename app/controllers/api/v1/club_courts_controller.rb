# frozen_string_literal: true

module Api
  module V1
    class ClubCourtsController < BaseController
      include ClubOwnerAuthorization

      before_action :require_club_owner!
      before_action :set_owned_club, only: %i[index create]
      before_action :set_owned_court, only: %i[update destroy]

      def index
        @courts = @club.courts.includes(:club).order(:name)
        render :index
      end

      def create
        @court = @club.courts.build(court_params)

        if @court.save
          @court = Court.includes(:club).find(@court.id)
          render :show, status: :created
        else
          render_record_errors(@court)
        end
      end

      def update
        if @court.update(court_params)
          @court = Court.includes(:club).find(@court.id)
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

      def court_params
        params.permit(:name, :court_type, :price_per_hour, :description, :status)
      end
    end
  end
end
