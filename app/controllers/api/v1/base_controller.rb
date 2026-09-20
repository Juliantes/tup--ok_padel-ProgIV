module Api
  module V1
    class BaseController < ActionController::API
      include JwtAuthenticatable
      include Pagy::Method

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def render_error(message, status:)
        render json: { error: message }, status: status
      end

      def not_found
        render_error("Not found", status: :not_found)
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render_error(exception.message, status: :bad_request)
      end
    end
  end
end
