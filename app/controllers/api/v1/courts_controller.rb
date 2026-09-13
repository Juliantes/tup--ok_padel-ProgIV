module Api
  module V1
    class CourtsController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[index show]

      def index
        @courts = Court.includes(:club).active.order(:name)
        render :index
      end

      def show
        @court = Court.includes(:club).active.find(params[:id])
        render :show
      end
    end
  end
end
