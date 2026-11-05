# frozen_string_literal: true

module Api
  module V1
    class ClubCourtTimeSlotsController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club
      before_action :set_court
      before_action :set_time_slot, only: %i[update destroy]

      def index
        if params[:date].present?
          render_for_date
          return
        end

        @time_slots = @court.time_slots.weekly_template.order(:day_of_week, :start_time)
        render :index
      end

      def create
        @time_slot = @court.time_slots.build(time_slot_attributes.merge(effective_on: nil))

        if @time_slot.save
          render :show, status: :created
        else
          render_record_errors(@time_slot)
        end
      end

      def bulk
        result = TimeSlots::BulkReplace.new(court: @court, params: bulk_params).call

        if result.success?
          @time_slots = result.time_slots
          render :index, status: :created
        else
          render json: {
            error: "unprocessable_entity",
            errors: result.errors,
            request_id: request.request_id
          }, status: :unprocessable_content
        end
      end

      def day_override
        case request.request_method
        when "PUT"
          replace_day_override
        when "DELETE"
          clear_day_override
        else
          head :method_not_allowed
        end
      end

      def update
        if @time_slot.effective_on.present?
          render json: {
            error: "unprocessable_entity",
            message: "Use day override to change date-specific slots",
            request_id: request.request_id
          }, status: :unprocessable_content
          return
        end

        if @time_slot.update(time_slot_attributes)
          render :show
        else
          render_record_errors(@time_slot)
        end
      end

      def destroy
        if @time_slot.effective_on.present?
          render json: {
            error: "unprocessable_entity",
            message: "Use day override to change date-specific slots",
            request_id: request.request_id
          }, status: :unprocessable_content
          return
        end

        @time_slot.destroy!
        head :no_content
      end

      private

      def render_for_date
        date = parse_date_param(params[:date])
        return if performed?

        resolver = TimeSlots::ForDate.new(court: @court, date: date)
        @schedule_date = date
        @day_of_week = date.wday
        @customized = resolver.customized?
        @time_slots = resolver.slots
        render :for_date
      end

      def replace_day_override
        date = parse_date_param(day_override_params[:date] || params[:date])
        return if performed?

        slots = day_override_params[:slots] || []
        result = TimeSlots::DayOverrideReplace.new(court: @court, date: date, slots: slots).call

        if result.success?
          @schedule_date = date
          @day_of_week = date.wday
          @customized = true
          @time_slots = result.time_slots
          render :for_date, status: :ok
        else
          render json: {
            error: "unprocessable_entity",
            errors: result.errors,
            request_id: request.request_id
          }, status: :unprocessable_content
        end
      end

      def clear_day_override
        date = parse_date_param(params[:date])
        return if performed?

        result = TimeSlots::DayOverrideClear.new(court: @court, date: date).call

        if result.success?
          head :no_content
        else
          render json: {
            error: "unprocessable_entity",
            errors: result.errors,
            request_id: request.request_id
          }, status: :unprocessable_content
        end
      end

      def parse_date_param(raw)
        if raw.blank?
          render_error("date is required", status: :unprocessable_content)
          return nil
        end

        Date.iso8601(raw.to_s)
      rescue ArgumentError
        render_error("date is invalid", status: :unprocessable_content)
        nil
      end

      def set_court
        @court = @club.courts.find(params[:court_id])
      end

      def set_time_slot
        @time_slot = @court.time_slots.find(params[:id])
      end

      def time_slot_attributes
        permitted = params.permit(:day_of_week, :start_time, :end_time, :is_available)
        attrs = permitted.to_h

        if attrs["start_time"].present?
          attrs["start_time"] = Time.zone.parse(attrs["start_time"])
        end
        if attrs["end_time"].present?
          attrs["end_time"] = Time.zone.parse(attrs["end_time"])
        end

        attrs
      end

      def bulk_params
        params.permit(:open_time, :close_time, :duration_minutes, day_of_weeks: [])
      end

      def day_override_params
        params.permit(:date, slots: [ :start_time, :end_time, :is_available ])
      end
    end
  end
end
