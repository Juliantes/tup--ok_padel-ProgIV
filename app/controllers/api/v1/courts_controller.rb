module Api
  module V1
    class CourtsController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[index show]

      def index
        @courts = Court.includes(:club).active.order(:name)
        if stale?(etag: courts_index_etag(@courts), public: true)
          render :index
        end
      end

      def show
        @court = Court.includes(:club).active.find(params[:id])
        render :show
      end

      private

      def courts_index_etag(courts)
        courts.map { |court| "#{court.cache_key_with_version}:#{court.club.cache_key_with_version}" }.join(",")
      end
    end
  end
end
