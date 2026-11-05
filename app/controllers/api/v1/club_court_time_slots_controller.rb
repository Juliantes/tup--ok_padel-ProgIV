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
    end
  end
end
