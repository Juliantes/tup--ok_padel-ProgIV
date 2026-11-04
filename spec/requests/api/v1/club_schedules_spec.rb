require "swagger_helper"

RSpec.describe "Api::V1::ClubSchedules", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:other_owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }

  let(:club) { create(:club, owner: owner) }
  let(:foreign_club) { create(:club, owner: other_owner) }
  let!(:court_a) { create(:court, club: club, name: "Cancha 1", status: :active) }
  let!(:court_b) { create(:court, club: club, name: "Cancha 2", status: :active) }

  let(:schedule_date) { Date.current.next_occurring(:monday) }
  let(:date) { schedule_date.iso8601 }

  let!(:slot_a) do
    create(
      :time_slot,
      court: court_a,
      day_of_week: schedule_date.wday,
      start_time: Time.zone.parse("10:00"),
      end_time: Time.zone.parse("11:30"),
    )
  end

  let!(:slot_b) do
    create(
      :time_slot,
      court: court_b,
      day_of_week: schedule_date.wday,
      start_time: Time.zone.parse("10:00"),
      end_time: Time.zone.parse("11:30"),
    )
  end

  path "/api/v1/clubs/{id}/schedule" do
    parameter name: :id, in: :path, type: :integer, description: "Club ID"
    parameter name: :date, in: :query, type: :string, format: :date, description: "Schedule date (ISO 8601)"

    get "Club schedule for a date" do
      tags "Owner clubs"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns courts, rows and cells for the day") do
        schema "$ref" => "#/components/schemas/ClubScheduleResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { club.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["date"]).to eq(date)
          expect(body["courts"].length).to eq(2)
          expect(body["rows"].map { |row| row["start_time"] }).to eq([ "10:00" ])

          cells = body["cells"]
          available = cells.select { |cell| cell["state"] == "available" }
          expect(available.length).to eq(2)
        end
      end

      response(200, "marks a slot as booked when a match uses it") do
        schema "$ref" => "#/components/schemas/ClubScheduleResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { club.id }

        before do
          create(
            :match,
            court: court_a,
            creator: player,
            time_slot: slot_a,
            date: schedule_date.change(hour: 10),
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          booked = body["cells"].find { |cell| cell["court_id"] == court_a.id && cell["start_time"] == "10:00" }
          expect(booked["state"]).to eq("booked")
          expect(booked["match_id"]).to be_present

          other = body["cells"].find { |cell| cell["court_id"] == court_b.id && cell["start_time"] == "10:00" }
          expect(other["state"]).to eq("available")
        end
      end

      response(200, "returns empty rows when there are no slots for the weekday") do
        schema "$ref" => "#/components/schemas/ClubScheduleResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { club.id }
        let(:date) { (schedule_date + 1.day).iso8601 }

        before do
          TimeSlot.delete_all
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["rows"]).to eq([])
          expect(body["cells"]).to eq([])
        end
      end

      response(422, "returns 422 when date is missing") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { club.id }
        let(:date) { nil }

        run_test! do |response|
          expect(JSON.parse(response.body)["error"]).to eq("date is required")
        end
      end

      response(403, "returns 403 for a player without club_owner role") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:id) { club.id }

        run_test!
      end

      response(404, "returns 404 for a foreign club") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { foreign_club.id }

        run_test!
      end
    end
  end
end
