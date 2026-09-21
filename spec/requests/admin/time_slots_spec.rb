require "rails_helper"

RSpec.describe "Admin::TimeSlots", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:court) { create(:court) }

  describe "GET /admin/courts/:court_id/time_slots" do
    it "redirects guests to sign in" do
      get admin_court_time_slots_path(court)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      sign_in create(:user, :player)

      get admin_court_time_slots_path(court)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You do not have permission to access the back office.")
    end

    it "allows admin users" do
      sign_in admin

      get admin_court_time_slots_path(court)

      expect(response).to have_http_status(:ok)
    end

    context "when signed in as admin" do
      before { sign_in admin }

      it "lists time slots for the court" do
        slot = create(:time_slot, court: court, day_of_week: 2)
        other_slot = create(:time_slot, court: create(:court))

        get admin_court_time_slots_path(court)

        expect(response.body).to include(slot.day_name)
        expect(response.body).not_to include(other_slot.day_name)
      end

      it "paginates when there are more than 20 time slots" do
        21.times do |i|
          start_hour = 6 + (i / 4)
          start_min = (i % 4) * 15
          end_min = start_min + 30
          end_hour = start_hour + (end_min >= 60 ? 1 : 0)
          end_min %= 60
          create(
            :time_slot,
            court: court,
            day_of_week: i % 7,
            start_time: Time.zone.parse(format("%02d:%02d", start_hour, start_min)),
            end_time: Time.zone.parse(format("%02d:%02d", end_hour, end_min))
          )
        end

        get admin_court_time_slots_path(court)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="pagination')
      end

      it "orders by day_of_week and start_time ascending" do
        late_monday = create(
          :time_slot,
          court: court,
          day_of_week: 1,
          start_time: Time.zone.parse("18:00"),
          end_time: Time.zone.parse("19:00")
        )
        sunday = create(
          :time_slot,
          court: court,
          day_of_week: 0,
          start_time: Time.zone.parse("10:00"),
          end_time: Time.zone.parse("11:00")
        )
        early_monday = create(
          :time_slot,
          court: court,
          day_of_week: 1,
          start_time: Time.zone.parse("08:00"),
          end_time: Time.zone.parse("09:00")
        )

        get admin_court_time_slots_path(court)

        body = response.body
        expect(body.index(sunday.day_name)).to be < body.index("08:00")
        expect(body.index("08:00")).to be < body.index("18:00")
      end
    end
  end

  describe "GET /admin/time_slots/:id" do
    let(:time_slot) { create(:time_slot, court: court) }

    before { sign_in admin }

    it "shows the time slot" do
      get admin_time_slot_path(time_slot)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(time_slot.day_name)
    end

    it "shows a warning when matches are associated" do
      match_date = 1.week.from_now.change(hour: 10, min: 0)
      aligned_slot = create(:time_slot, court: court, day_of_week: match_date.wday)
      create(:match, court: court, time_slot: aligned_slot, date: match_date)

      get admin_time_slot_path(aligned_slot)

      expect(response.body).to include("This time slot has 1 match")
    end

    it "does not show a warning when there are no matches" do
      get admin_time_slot_path(time_slot)

      expect(response.body).not_to include("This time slot has")
    end

    it "returns 404 when the time slot does not exist" do
      get admin_time_slot_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/courts/:court_id/time_slots/new" do
    before { sign_in admin }

    it "renders the new form" do
      get new_admin_court_time_slot_path(court)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/courts/:court_id/time_slots" do
    before { sign_in admin }

    let(:valid_params) do
      {
        time_slot: {
          day_of_week: 3,
          start_time: "10:00",
          end_time: "11:30",
          is_available: true
        }
      }
    end

    it "creates a time slot for the court" do
      expect {
        post admin_court_time_slots_path(court), params: valid_params
      }.to change(TimeSlot, :count).by(1)

      expect(response).to redirect_to(admin_time_slot_path(TimeSlot.last))
      expect(TimeSlot.last.court).to eq(court)
    end

    it "rejects end_time before or equal to start_time" do
      expect {
        post admin_court_time_slots_path(court), params: {
          time_slot: valid_params[:time_slot].merge(start_time: "12:00", end_time: "11:00")
        }
      }.not_to change(TimeSlot, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects day_of_week outside 0..6" do
      expect {
        post admin_court_time_slots_path(court), params: {
          time_slot: valid_params[:time_slot].merge(day_of_week: 7)
        }
      }.not_to change(TimeSlot, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects invalid day_of_week values" do
      expect {
        post admin_court_time_slots_path(court), params: {
          time_slot: valid_params[:time_slot].merge(day_of_week: "8")
        }
      }.not_to change(TimeSlot, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/time_slots/:id/edit" do
    let(:time_slot) { create(:time_slot, court: court) }

    before { sign_in admin }

    it "renders the edit form" do
      get edit_admin_time_slot_path(time_slot)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/time_slots/:id" do
    let(:time_slot) { create(:time_slot, court: court) }

    before { sign_in admin }

    it "updates the time slot" do
      patch admin_time_slot_path(time_slot), params: {
        time_slot: {
          day_of_week: 4,
          start_time: "14:00",
          end_time: "15:30",
          is_available: false
        }
      }

      expect(response).to redirect_to(admin_time_slot_path(time_slot))
      expect(time_slot.reload.day_of_week).to eq(4)
      expect(time_slot.is_available).to be(false)
    end

    it "rejects end_time before or equal to start_time" do
      patch admin_time_slot_path(time_slot), params: {
        time_slot: {
          day_of_week: time_slot.day_of_week,
          start_time: "12:00",
          end_time: "11:00",
          is_available: time_slot.is_available
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/time_slots/:id" do
    let!(:time_slot) { create(:time_slot, court: court) }

    before { sign_in admin }

    it "deletes the time slot" do
      expect {
        delete admin_time_slot_path(time_slot)
      }.to change(TimeSlot, :count).by(-1)

      expect(response).to redirect_to(admin_court_time_slots_path(court))
    end

    it "deletes the time slot and nullifies associated matches" do
      match_date = 1.week.from_now.change(hour: 10, min: 0)
      time_slot.update!(day_of_week: match_date.wday)
      match = create(:match, court: court, time_slot: time_slot, date: match_date)

      expect {
        delete admin_time_slot_path(time_slot)
      }.to change(TimeSlot, :count).by(-1)

      expect(response).to redirect_to(admin_court_time_slots_path(court))
      expect(match.reload.time_slot_id).to be_nil
    end
  end
end
