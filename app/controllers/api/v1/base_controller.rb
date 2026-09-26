module Api
  module V1
    class BaseController < ActionController::API
      include JwtAuthenticatable
      include Pagy::Method

      around_action :force_english_locale

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def render_error(message, status:)
        render json: {
          error: message,
          request_id: request.request_id
        }, status: status
      end

      def not_found
        render_error("Not found", status: :not_found)
      end

      def unprocessable_entity(exception)
        render_record_errors(exception.record)
      end

      def bad_request(exception)
        render_error(exception.message, status: :bad_request)
      end

      def force_english_locale(&block)
        I18n.with_locale(:en, &block)
      end

      def render_record_errors(record)
        render json: {
          error: "unprocessable_entity",
          errors: record.errors.to_hash,
          request_id: request.request_id
        }, status: :unprocessable_content
      end
    end
  end
end
