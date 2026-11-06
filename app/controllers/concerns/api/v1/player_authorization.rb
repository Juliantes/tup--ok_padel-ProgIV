# frozen_string_literal: true

module Api
  module V1
    module PlayerAuthorization
      extend ActiveSupport::Concern

      included do
        before_action :require_player!
      end

      private

      def require_player!
        return if current_user&.player?

        render_error("player role required", status: :forbidden)
      end
    end
  end
end
