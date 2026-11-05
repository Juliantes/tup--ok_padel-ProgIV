require "swagger_helper"

RSpec.describe "Api::V1::WalkInBookings", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }

  let(:club) { create(:club, owner: owner) }
  let!(:court) { create(:court, club: club, status: :active) }
  let!(:inactive_court) { create(:court, club: club, status: :inactive) }

  let(:booking_date) { Date.current.next_occurring(:monday) }

  let!(:slot) do
    create(
      :time_slot,
      court: court,
      day_of_week: booking_date.wday,
      start_time: Time.zone.parse("10:00"),
      end_time: Time.zone.parse("11:30"),
    )
  end

  let(:valid_booking_body) do
    {
      court_id: court.id,
      time_slot_id: slot.id,
      date: booking_date.iso8601,
      walk_in_guest_name: "Juan",
      walk_in_guest_phone: "+5491112345678"
    }
  end

  path "/api/v1/clubs/{club_id}/walk_in_bookings" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"

    post "Create walk-in booking" do
      tags "Owner clubs"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          court_id: { type: :integer },
          time_slot_id: { type: :integer },
          date: { type: :string, format: :date },
          walk_in_guest_name: { type: :string, nullable: true },
          walk_in_guest_phone: { type: :string, nullable: true }
        },
        required: %w[court_id time_slot_id date]
      }

      response(201, "creates a confirmed walk-in match") do
        schema "$ref" => "#/components/schemas/WalkInBookingResponse"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) { valid_booking_body }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          match = body_json["match"]
          expect(match["status"]).to eq("confirmed")
          expect(match["walk_in_guest_name"]).to eq("Juan")
          expect(Match.find(match["id"]).walk_in?).to be(true)
        end
      end

      response(422, "returns 422 when slot already booked") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) { valid_booking_body }

        before do
          create(
            :match,
            court: court,
            creator: player,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
          )
        end

        run_test!
      end

      response(422, "returns 422 when weekday mismatches") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) { valid_booking_body.merge(date: booking_date.next_day.iso8601) }

        run_test!
      end

      response(422, "returns 422 when court is inactive") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let(:body) do
          inactive_slot = create(
            :time_slot,
            court: inactive_court,
            day_of_week: booking_date.wday,
            start_time: Time.zone.parse("12:00"),
            end_time: Time.zone.parse("13:30"),
          )
          valid_booking_body.merge(court_id: inactive_court.id, time_slot_id: inactive_slot.id)
        end

        run_test!
      end
    end
  end

  path "/api/v1/clubs/{club_id}/walk_in_bookings/{id}" do
    parameter name: :club_id, in: :path, type: :integer, description: "Club ID"
    parameter name: :id, in: :path, type: :integer, description: "Match ID"

    delete "Cancel walk-in booking" do
      tags "Owner clubs"
      security [ { bearer_auth: [] } ]

      response(204, "cancels a walk-in match") do
        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let!(:walk_in_match) do
          create(
            :match,
            court: court,
            creator: owner,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
            walk_in: true,
            join_policy: :manual,
          )
        end
        let(:id) { walk_in_match.id }

        run_test! do
          expect(walk_in_match.reload).to be_cancelled
        end
      end

      response(422, "returns 422 when match is not walk-in") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:club_id) { club.id }
        let!(:regular_match) do
          create(
            :match,
            court: court,
            creator: player,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
          )
        end
        let(:id) { regular_match.id }

        run_test!
      end
    end
  end
end
