module Admin
  class ClubsController < BaseController
    before_action :set_club, only: %i[show edit update destroy]

    def index
      @pagy, @clubs = pagy(:offset, Club.includes(:owner).order(:name))
    end

    def show
    end

    def new
      @club = Club.new
    end

    def create
      @club = Club.new(club_params)

      if @club.save
        redirect_to admin_club_path(@club), notice: "Club was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @club.update(club_params)
        redirect_to admin_club_path(@club), notice: "Club was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @club.destroy
        redirect_to admin_clubs_path, notice: "Club was successfully deleted."
      else
        redirect_to admin_club_path(@club), alert: @club.errors.full_messages.to_sentence
      end
    end

    private

    def set_club
      @club = Club.find(params[:id])
    end

    def club_params
      params.require(:club).permit(:name, :address, :phone, :email, :owner_id)
    end
  end
end
