module Api
  module V1
    class UsersController < BaseController
      def show
        @user = current_user
        render :show
      end

      def update
        if current_user.update(user_params)
          @user = current_user
          render :show
        else
          render_record_errors(current_user)
        end
      end

      private

      def user_params
        params.permit(:name, :phone, :self_level, :bio)
      end
    end
  end
end
