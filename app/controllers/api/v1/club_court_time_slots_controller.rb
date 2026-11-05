# frozen_string_literal: true

module Api
  module V1
    class ClubCourtTimeSlotsController < BaseController
      include ClubOwnerAuthorization

      before_action :set_owned_club
      before_action :set_court
      before_action :set_time_slot, only: %i[update destroy]

      def index
        @time_slots = @court.time_slots.order(:day_of_week, :start_time)
        render :index
      end

      def create
        @time_slot = @court.time_slots.build(time_slot_attributes)

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

      def update
        if @time_slot.update(time_slot_attributes)
          render :show
        else
          render_record_errors(@time_slot)
        end
      end

      def destroy
        @time_slot.destroy!
        head :no_content
      end

      private

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
    end
  end
end
