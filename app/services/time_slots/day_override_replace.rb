# frozen_string_literal: true

module TimeSlots
  class DayOverrideReplace
    Result = Data.define(:success, :time_slots, :errors) do
      def success?
        success
      end
    end

    def initialize(court:, date:, slots:)
      @court = court
      @date = date.to_date
      @slots = Array(slots)
    end

    def call
      validation_errors = validate_slots
      return failure(validation_errors) if validation_errors.present?

      if bookings_on_date?
        return failure(base: [ I18n.t("time_slots.day_override.future_bookings") ])
      end

      day_of_week = @date.wday

      ActiveRecord::Base.transaction do
        @court.time_slots.for_effective_date(@date).destroy_all

        @slots.each do |attrs|
          @court.time_slots.create!(
            day_of_week: day_of_week,
            effective_on: @date,
            start_time: parse_time(attrs[:start_time] || attrs["start_time"]),
            end_time: parse_time(attrs[:end_time] || attrs["end_time"]),
            is_available: attrs.fetch(:is_available, attrs["is_available"].nil? ? true : attrs["is_available"]),
          )
        end

        @court.court_day_overrides.find_or_create_by!(date: @date)
      end

      resolver = ForDate.new(court: @court, date: @date)
      success(resolver.slots.to_a)
    end

    private

    def success(time_slots)
      Result.new(success: true, time_slots: time_slots, errors: {})
    end

    def failure(errors)
      Result.new(success: false, time_slots: nil, errors: errors)
    end

    def validate_slots
      errors = {}
      @slots.each_with_index do |slot, index|
        start_str = normalize_time_param(slot[:start_time] || slot["start_time"])
        end_str = normalize_time_param(slot[:end_time] || slot["end_time"])
        if start_str.blank? || end_str.blank?
          errors[:"slots[#{index}]"] = [ I18n.t("time_slots.day_override.invalid_times") ]
          next
        end

        open_at = Time.zone.parse("#{Date.current} #{start_str}")
        close_at = Time.zone.parse("#{Date.current} #{end_str}")
        if open_at.nil? || close_at.nil? || open_at >= close_at
          errors[:"slots[#{index}]"] = [ I18n.t("time_slots.day_override.invalid_times") ]
        end
      end

      errors.presence
    end

    def normalize_time_param(value)
      return nil if value.blank?

      parsed = Time.zone.parse(value.to_s)
      return nil if parsed.nil?

      parsed.strftime("%H:%M")
    end

    def parse_time(value)
      Time.zone.parse(normalize_time_param(value))
    end

    def bookings_on_date?
      Match.where(court_id: @court.id)
           .where.not(status: :cancelled)
           .where(date: @date.all_day)
           .exists?
    end
  end
end
