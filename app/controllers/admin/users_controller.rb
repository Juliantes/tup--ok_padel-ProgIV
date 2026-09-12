module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update]

    def index
      @pagy, @users = pagy(:offset, User.includes(:user_roles).order(:name))
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        sync_roles!
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :phone, :self_level, :bio)
    end

    def selected_roles
      User::ROLES.select { |role| params.dig(:user, "role_#{role}") == "1" }
    end

    def sync_roles!
      selected_roles.each do |role|
        @user.user_roles.find_or_create_by!(role: role)
      end

      @user.user_roles.where.not(role: selected_roles).destroy_all
    end
  end
end
