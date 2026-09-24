module Admin
  class CourtsController < BaseController
    before_action :set_court, only: %i[show edit update destroy]

    def index
      @pagy, @courts = pagy(:offset, Court.includes(:club).order(:name))
    end

    def show
    end

    def new
      @court = Court.new
    end

    def create
      @court = Court.new(court_params)

      if @court.save
        redirect_to admin_court_path(@court), notice: "Court was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @court.update(court_params)
        redirect_to admin_court_path(@court), notice: "Court was successfully updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @court.destroy!
      redirect_to admin_courts_path, notice: "Court was successfully deleted."
    end

    private

    def set_court
      @court = Court.find(params[:id])
    end

    def court_params
      params.require(:court).permit(:club_id, :name, :court_type, :price_per_hour, :description, :status, :image)
    end
  end
end
