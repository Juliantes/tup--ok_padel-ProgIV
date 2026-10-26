# frozen_string_literal: true

module Api
  module V1
    class ClubsController < BaseController
      include ClubOwnerAuthorization

      before_action :require_club_owner!
      before_action :set_owned_club, only: %i[update destroy]

      def index
        @clubs = current_user.owned_clubs.order(:name)
        render :index
      end

      def create
        @club = current_user.owned_clubs.build(club_params)

        if @club.save
          render :show, status: :created
        else
          render_record_errors(@club)
        end
      end

      def update
        if @club.update(club_params)
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

      def set_owned_club
        @club = current_user.owned_clubs.find(params[:id])
      end

      def club_params
        params.permit(:name, :address, :phone, :email)
      end
    end
  end
end
