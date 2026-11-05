# frozen_string_literal: true

module TimeSlots
  class DayOverrideClear
    Result = Data.define(:success, :errors) do
      def success?
        success
      end
    end

    def initialize(court:, date:)
      @court = court
      @date = date.to_date
    end

    def call
      if bookings_on_date?
        return Result.new(success: false, errors: { base: [ I18n.t("time_slots.day_override.future_bookings") ] })
      end

      ActiveRecord::Base.transaction do
        @court.time_slots.for_effective_date(@date).destroy_all
        @court.court_day_overrides.where(date: @date).delete_all
      end

      Result.new(success: true, errors: {})
    end

    private

    def bookings_on_date?
      Match.where(court_id: @court.id)
           .where.not(status: :cancelled)
           .where(date: @date.all_day)
           .exists?
    end
  end
end
