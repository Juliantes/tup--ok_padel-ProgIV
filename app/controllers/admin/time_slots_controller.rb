module Admin
  class TimeSlotsController < BaseController
    before_action :set_court, only: %i[index new create]
    before_action :set_time_slot, only: %i[show edit update destroy]

    def index
      @pagy, @time_slots = pagy(:offset, @court.time_slots.order(:day_of_week, :start_time))
    end

    def show
    end

    def new
      @time_slot = @court.time_slots.build
    end

    def create
      @time_slot = @court.time_slots.build(time_slot_params)

      if @time_slot.save
        redirect_to admin_time_slot_path(@time_slot), notice: "Time slot was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @time_slot.update(time_slot_params)
        redirect_to admin_time_slot_path(@time_slot), notice: "Time slot was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      court = @time_slot.court
      @time_slot.destroy!
      redirect_to admin_court_time_slots_path(court), notice: "Time slot was successfully deleted."
    end

    private

    def set_court
      @court = Court.find(params[:court_id])
    end

    def set_time_slot
      @time_slot = TimeSlot.find(params[:id])
    end

    def time_slot_params
      params.require(:time_slot).permit(:day_of_week, :start_time, :end_time, :is_available)
    end
  end
end
