module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_api_user!, only: :create

      def create
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          @user = user
          @token = token
          render :create, status: :ok
        else
          render_error("Invalid credentials", status: :unauthorized)
        end
      end

      private

      def login_params
        params.permit(:email, :password)
      end
    end
  end
end
