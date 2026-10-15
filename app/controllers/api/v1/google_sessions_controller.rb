# frozen_string_literal: true

module Api
  module V1
    class GoogleSessionsController < BaseController
      skip_before_action :authenticate_api_user!, only: :create

      def create
        claims = FirebaseIdTokenVerifier.verify(oauth_params[:id_token])
        @user = FirebaseOAuthUserProvisioner.call(claims)
        @token = JsonWebToken.encode(user_id: @user.id)
        render "api/v1/sessions/create", status: :ok
      rescue FirebaseIdTokenVerifier::VerificationError
        render_error("Invalid token", status: :unauthorized)
      rescue ActiveRecord::RecordInvalid => e
        render_record_errors(e.record)
      end

      private

      def oauth_params
        params.permit(:id_token)
      end
    end
  end
end
