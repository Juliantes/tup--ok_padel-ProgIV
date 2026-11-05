require "swagger_helper"

RSpec.describe "Api::V1::OwnerClubTimeSlots", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:other_owner) { create(:user, :club_owner) }

  let(:club) { create(:club, owner: owner) }
  let(:foreign_club) { create(:club, owner: other_owner) }
  let(:court) { create(:court, club: club, status: :active) }
  let(:foreign_court) { create(:court, club: foreign_club) }

  let(:valid_slot_body) do
    {
      day_of_week: 1,
      start_time: "10:00",
      end_time: "11:30",
      is_available: true
    }
  end

  path "/api/v1/clubs/{club_id}/courts/{court_id}/time_slots" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :court_id, in: :path, type: :integer, description: "Court ID"

    get "List time slots for owned court" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :date, in: :query, type: :string, required: false, description: "ISO date for effective slots"

      response(200, "lists time slots") do
        schema type: :object,
               properties: {
                 time_slots: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/OwnerTimeSlot" }
                 }
               },
               required: [ "time_slots" ]

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }

        before do
          create(:time_slot, court: court, day_of_week: 1, start_time: "09:00", end_time: "10:00")
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["time_slots"].length).to eq(1)
        end
      end

      response(200, "lists effective slots for a date") do
        schema "$ref" => "#/components/schemas/OwnerTimeSlotsForDateResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:date) { Date.current.next_occurring(:monday).iso8601 }

        before do
          create(:time_slot, court: court, day_of_week: 1, start_time: "09:00", end_time: "10:00")
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["customized"]).to be(false)
          expect(body["time_slots"].length).to eq(1)
        end
      end

      response(404, "returns 404 for foreign club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { foreign_club.id }
        let(:court_id) { foreign_court.id }

        run_test!
      end
    end

    post "Create time slot" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          day_of_week: { type: :integer },
          start_time: { type: :string, example: "10:00" },
          end_time: { type: :string, example: "11:30" },
          is_available: { type: :boolean }
        },
        required: %w[day_of_week start_time end_time]
      }

      response(201, "creates a time slot") do
        schema "$ref" => "#/components/schemas/OwnerTimeSlotResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:body) { valid_slot_body }

        run_test!
      end

      response(422, "returns 422 when slots overlap") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:body) { valid_slot_body.merge(start_time: "10:30", end_time: "12:00") }

        before do
          create(
            :time_slot,
            court: court,
            day_of_week: 1,
            start_time: Time.zone.parse("10:00"),
            end_time: Time.zone.parse("11:30"),
          )
        end

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{club_id}/courts/{court_id}/time_slots/bulk" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :court_id, in: :path, type: :integer, description: "Court ID"

    post "Bulk replace time slots" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          open_time: { type: :string, example: "08:00" },
          close_time: { type: :string, example: "23:00" },
          duration_minutes: { type: :integer, example: 90 },
          day_of_weeks: { type: :array, items: { type: :integer } },
        },
        required: %w[open_time close_time duration_minutes day_of_weeks],
      }

      let(:bulk_body) do
        {
          open_time: "08:00",
          close_time: "23:00",
          duration_minutes: 90,
          day_of_weeks: [ 1, 2, 3, 4, 5 ],
        }
      end

      response(201, "replaces slots and returns full court list") do
        schema type: :object,
               properties: {
                 time_slots: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/OwnerTimeSlot" },
                 },
               },
               required: [ "time_slots" ]

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:body) { bulk_body }

        before do
          create(:time_slot, court: court, day_of_week: 1, start_time: "10:00", end_time: "11:00")
        end

        run_test! do |response|
          parsed = JSON.parse(response.body)
          monday_slots = parsed["time_slots"].select { |s| s["day_of_week"] == 1 }
          expect(monday_slots.length).to eq(10)
          expect(monday_slots.first["start_time"]).to eq("08:00")
          expect(monday_slots.last["end_time"]).to eq("23:00")
        end
      end

      response(422, "blocked by future booking") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:body) { bulk_body }

        before do
          slot = create(:time_slot, court: court, day_of_week: 1, start_time: "10:00", end_time: "11:30")
          booking_date = Date.current.next_occurring(:monday)
          create(
            :match,
            court: court,
            time_slot: slot,
            date: booking_date.in_time_zone.change(hour: 10),
            status: :confirmed,
            walk_in: true,
          )
        end

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{club_id}/courts/{court_id}/time_slots/day_override" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :court_id, in: :path, type: :integer, description: "Court ID"

    put "Replace time slots for a single date" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          date: { type: :string, format: :date },
          slots: {
            type: :array,
            items: {
              type: :object,
              properties: {
                start_time: { type: :string },
                end_time: { type: :string },
                is_available: { type: :boolean }
              },
              required: %w[start_time end_time]
            }
          }
        },
        required: %w[date slots]
      }

      response(200, "stores override for date") do
        schema "$ref" => "#/components/schemas/OwnerTimeSlotsForDateResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:override_date) { Date.current.next_occurring(:monday) }
        let(:body) do
          {
            date: override_date.iso8601,
            slots: [
              { start_time: "09:00", end_time: "10:30", is_available: true }
            ]
          }
        end

        run_test! do |response|
          parsed = JSON.parse(response.body)
          expect(parsed["customized"]).to be(true)
          expect(parsed["time_slots"].length).to eq(1)
        end
      end
    end

    delete "Clear date override" do
      tags "Owner clubs"
      security [ { bearer_auth: [] } ]
      parameter name: :date, in: :query, type: :string, required: true

      response(204, "removes override") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:date) { Date.current.next_occurring(:monday).iso8601 }

        before do
          TimeSlots::DayOverrideReplace.new(
            court: court,
            date: Date.iso8601(date),
            slots: [ { start_time: "09:00", end_time: "10:00", is_available: true } ],
          ).call
        end

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{club_id}/courts/{court_id}/time_slots/{id}" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :court_id, in: :path, type: :integer, description: "Court ID"
    parameter name: :id, in: :path, type: :integer, description: "Time slot ID"

    let!(:time_slot) do
      create(
        :time_slot,
        court: court,
        day_of_week: 2,
        start_time: Time.zone.parse("08:00"),
        end_time: Time.zone.parse("09:30"),
      )
    end

    patch "Update time slot" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          is_available: { type: :boolean }
        }
      }

      response(200, "updates a time slot") do
        schema "$ref" => "#/components/schemas/OwnerTimeSlotResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:id) { time_slot.id }
        let(:body) { { is_available: false } }

        run_test! do |response|
          expect(JSON.parse(response.body).dig("time_slot", "is_available")).to be(false)
        end
      end
    end

    delete "Delete time slot" do
      tags "Owner clubs"
      security [ { bearer_auth: [] } ]

      response(204, "deletes a time slot") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:court_id) { court.id }
        let(:id) { time_slot.id }

        run_test!
      end
    end
  end
end
