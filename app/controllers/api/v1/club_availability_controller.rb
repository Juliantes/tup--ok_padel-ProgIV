# frozen_string_literal: true

module Api
  module V1
    class ClubAvailabilityController < BaseController
      include PlayerAuthorization

      before_action :set_club

      def show
        date = parse_schedule_date
        return if performed?

        courts_scope = @club.courts.where.not(status: :inactive)
        @schedule = ClubScheduleBuilder.new(club: @club, date: date, courts_scope: courts_scope).build
        render :show
      end

      private

      def set_club
        @club = Club.find(params[:id])
      end

      def parse_schedule_date
        raw = params[:date]
        if raw.blank?
          render_error("date is required", status: :unprocessable_content)
          return nil
        end

        Date.iso8601(raw)
      rescue ArgumentError
        render_error("date is invalid", status: :unprocessable_content)
        nil
      end
    end
  end
end
