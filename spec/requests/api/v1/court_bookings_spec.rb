# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::CourtBookings", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }
  let(:other_player) { create(:user, :player) }

  let(:club) { create(:club, owner: owner) }
  let!(:court) { create(:court, club: club, status: :active, price_per_hour: 120) }

  let(:booking_date) { 1.week.from_now.to_date.next_occurring(:monday) }

  let!(:slot) do
    create(
      :time_slot,
      court: court,
      day_of_week: booking_date.wday,
      start_time: Time.zone.parse("10:00"),
      end_time: Time.zone.parse("11:30"),
    )
  end

  let(:valid_body) do
    {
      club_id: club.id,
      court_id: court.id,
      time_slot_id: slot.id,
      date: booking_date.iso8601
    }
  end

  path "/api/v1/court_bookings" do
    post "Create court booking" do
      tags "Player courts"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          club_id: { type: :integer },
          court_id: { type: :integer },
          time_slot_id: { type: :integer },
          date: { type: :string, format: :date }
        },
        required: %w[club_id court_id time_slot_id date]
      }

      response(201, "creates a confirmed player booking") do
        schema "$ref" => "#/components/schemas/CourtBookingResponse"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:body) { valid_body }

        run_test! do |response|
          body_json = JSON.parse(response.body)
          booking = body_json["court_booking"]
          expect(booking["status"]).to eq("confirmed")
          expect(booking["player_booking"]).to be(true)
          expect(booking["estimated_price"]).to eq(180.0)
          expect(Match.find(booking["id"]).player_booking?).to be(true)
        end
      end

      response(422, "returns 422 when slot already booked") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:body) { valid_body }

        before do
          create(
            :match,
            court: court,
            creator: other_player,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
          )
        end

        run_test!
      end

      response(403, "returns 403 without player role") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:body) { valid_body }

        run_test!
      end
    end
  end

  path "/api/v1/me/court_bookings" do
    get "List my court bookings" do
      tags "Player courts"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns player bookings with cancellable flag") do
        schema "$ref" => "#/components/schemas/CourtBookingsIndexResponse"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }

        before do
          create(
            :match,
            court: court,
            creator: player,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
            player_booking: true,
            walk_in: false,
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["court_bookings"].length).to eq(1)
          expect(body["court_bookings"].first["cancellable"]).to be(true)
        end
      end
    end
  end

  path "/api/v1/court_bookings/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Court booking ID"

    delete "Cancel court booking" do
      tags "Player courts"
      security [ { bearer_auth: [] } ]

      response(204, "cancels the booking") do
        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let!(:booking) do
          create(
            :match,
            court: court,
            creator: player,
            time_slot: slot,
            date: booking_date.change(hour: 10),
            status: :confirmed,
            player_booking: true,
            walk_in: false,
          )
        end
        let(:id) { booking.id }

        run_test! do
          expect(booking.reload.status).to eq("cancelled")
        end
      end

      response(422, "returns 422 when too late to cancel") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:soon_date) { 1.hour.from_now }
        let!(:soon_slot) do
          create(
            :time_slot,
            court: court,
            day_of_week: soon_date.wday,
            start_time: Time.zone.parse(soon_date.strftime("%H:%M")),
            end_time: Time.zone.parse((soon_date + 90.minutes).strftime("%H:%M")),
          )
        end
        let!(:booking) do
          create(
            :match,
            court: court,
            creator: player,
            time_slot: soon_slot,
            date: soon_date.change(min: 0, sec: 0),
            status: :confirmed,
            player_booking: true,
            walk_in: false,
          )
        end
        let(:id) { booking.id }

        run_test!
      end
    end
  end
end
