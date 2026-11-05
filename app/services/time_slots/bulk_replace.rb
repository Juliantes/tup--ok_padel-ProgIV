# frozen_string_literal: true

module TimeSlots
  class BulkReplace
    Result = Data.define(:success, :time_slots, :errors) do
      def success?
        success
      end
    end

    def self.build_intervals(open_time:, close_time:, duration_minutes:)
      anchor = Date.current
      open_at = Time.zone.parse("#{anchor} #{open_time}")
      close_at = Time.zone.parse("#{anchor} #{close_time}")
      return [] if open_at.nil? || close_at.nil? || open_at >= close_at

      step = duration_minutes.to_i.minutes
      return [] if step <= 0

      intervals = []
      cursor = open_at
      while cursor + step <= close_at
        intervals << [ cursor, cursor + step ]
        cursor += step
      end
      intervals
    end

    def initialize(court:, params:)
      @court = court
      @params = params
    end

    def call
      validation_errors = validate
      return failure(validation_errors) if validation_errors.present?

      intervals = self.class.build_intervals(
        open_time: @open_time_str,
        close_time: @close_time_str,
        duration_minutes: @duration_minutes,
      )
      return failure(base: [ I18n.t("time_slots.bulk_replace.no_slots_fit") ]) if intervals.empty?

      days = @day_of_weeks
      slots_to_remove = @court.time_slots.weekly_template.where(day_of_week: days)

      if future_bookings?(slots_to_remove)
        return failure(base: [ I18n.t("time_slots.bulk_replace.future_bookings") ])
      end

      ActiveRecord::Base.transaction do
        slots_to_remove.destroy_all

        days.each do |day_of_week|
          intervals.each do |start_time, end_time|
            @court.time_slots.create!(
              day_of_week: day_of_week,
              effective_on: nil,
              start_time: start_time,
              end_time: end_time,
              is_available: true,
            )
          end
        end
      end

      success(@court.time_slots.order(:day_of_week, :start_time))
    end

    private

    def success(time_slots)
      Result.new(success: true, time_slots: time_slots, errors: {})
    end

    def failure(errors)
      Result.new(success: false, time_slots: nil, errors: errors)
    end

    def validate
      errors = {}

      days = Array(@params[:day_of_weeks]).map { |d| d.to_i }.uniq
      if days.empty? || days.size > 7
        errors[:day_of_weeks] = [ I18n.t("time_slots.bulk_replace.invalid_days") ]
      elsif days.any? { |d| d < 0 || d > 6 }
        errors[:day_of_weeks] = [ I18n.t("time_slots.bulk_replace.invalid_days") ]
      else
        @day_of_weeks = days.sort
      end

      @duration_minutes = @params[:duration_minutes].to_i
      if @duration_minutes <= 0
        errors[:duration_minutes] = [ I18n.t("time_slots.bulk_replace.invalid_duration") ]
      end

      @open_time_str = normalize_time_param(@params[:open_time])
      @close_time_str = normalize_time_param(@params[:close_time])

      if @open_time_str.blank? || @close_time_str.blank?
        errors[:open_time] = [ I18n.t("time_slots.bulk_replace.invalid_times") ] if @open_time_str.blank?
        errors[:close_time] = [ I18n.t("time_slots.bulk_replace.invalid_times") ] if @close_time_str.blank?
      else
        open_at = Time.zone.parse("#{Date.current} #{@open_time_str}")
        close_at = Time.zone.parse("#{Date.current} #{@close_time_str}")
        if open_at.nil? || close_at.nil? || open_at >= close_at
          errors[:base] = [ I18n.t("time_slots.bulk_replace.open_before_close") ]
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

    def future_bookings?(slots_scope)
      slot_ids = slots_scope.pluck(:id)
      return false if slot_ids.empty?

      Match.where(time_slot_id: slot_ids)
           .where.not(status: :cancelled)
           .where(date: Time.zone.today.beginning_of_day..)
           .exists?
    end
  end
end
