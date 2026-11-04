# frozen_string_literal: true

module Api
  module V1
    class ClubSchedulesController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club

      def show
        date = parse_schedule_date
        return if performed?

        @schedule = ClubScheduleBuilder.new(club: @club, date: date).build
        render :show
      end

      private

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
