module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @pagy, @users = pagy(:offset, User.includes(:user_roles).order(:name))
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.password = params.dig(:user, :password)
      @user.password_confirmation = params.dig(:user, :password_confirmation)

      if @user.save
        sync_roles!(default_player: true)
        redirect_to admin_user_path(@user), notice: "User was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attributes = user_params
      if params.dig(:user, :password).present?
        attributes[:password] = params.dig(:user, :password)
        attributes[:password_confirmation] = params.dig(:user, :password_confirmation)
      end

      if @user.update(attributes)
        sync_roles!
        redirect_to admin_user_path(@user), notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user.destroy
        redirect_to admin_users_path, notice: "User was successfully deleted."
      else
        redirect_to admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :name, :phone, :self_level, :bio)
    end

    def selected_roles(default_player: false)
      roles = User::ROLES.select { |role| params.dig(:user, "role_#{role}") == "1" }
      roles = ["player"] if roles.empty? && default_player
      roles
    end

    def sync_roles!(default_player: false)
      roles = selected_roles(default_player: default_player)

      roles.each do |role|
        @user.user_roles.find_or_create_by!(role: role)
      end

      @user.user_roles.where.not(role: roles).destroy_all
    end
  end
end
