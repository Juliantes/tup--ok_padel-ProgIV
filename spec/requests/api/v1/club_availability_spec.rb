# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Api::V1::ClubAvailability", type: :request do
  let(:owner) { create(:user, :club_owner) }
  let(:player) { create(:user, :player) }

  let(:club) { create(:club, owner: owner) }
  let!(:active_court) { create(:court, club: club, name: "Activa", status: :active) }
  let!(:inactive_court) { create(:court, club: club, name: "Inactiva", status: :inactive) }

  let(:schedule_date) { Date.current.next_occurring(:monday) }
  let(:date) { schedule_date.iso8601 }

  let!(:slot) do
    create(
      :time_slot,
      court: active_court,
      day_of_week: schedule_date.wday,
      start_time: Time.zone.parse("10:00"),
      end_time: Time.zone.parse("11:30"),
    )
  end

  path "/api/v1/clubs/{id}/availability" do
    parameter name: :id, in: :path, type: :integer, description: "Club ID"
    parameter name: :date, in: :query, type: :string, format: :date, description: "Schedule date (ISO 8601)"

    get "Club availability for players" do
      tags "Player courts"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response(200, "returns availability without inactive courts") do
        schema "$ref" => "#/components/schemas/PlayerAvailabilityResponse"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:id) { club.id }

        run_test! do |response|
          body = JSON.parse(response.body)
          court_ids = body["courts"].map { |court| court["id"] }
          expect(court_ids).to include(active_court.id)
          expect(court_ids).not_to include(inactive_court.id)
          expect(body["cells"].none? { |cell| cell.key?("match_id") }).to be(true)
        end
      end

      response(200, "includes club lat and lng when geocoded") do
        schema "$ref" => "#/components/schemas/PlayerAvailabilityResponse"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:id) { club.id }

        before do
          club.update!(lat: -32.94682, lng: -60.63932, place_id: "geoapify-test-place")
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          expect(body["club"]["lat"]).to be_within(0.0001).of(-32.94682)
          expect(body["club"]["lng"]).to be_within(0.0001).of(-60.63932)
        end
      end

      response(200, "returns match_id only for booked matches that are not court-only") do
        schema "$ref" => "#/components/schemas/PlayerAvailabilityResponse"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:id) { club.id }

        let!(:court_b) { create(:court, club: club, name: "B", status: :active) }
        let!(:slot_b) do
          create(
            :time_slot,
            court: court_b,
            day_of_week: schedule_date.wday,
            start_time: Time.zone.parse("10:00"),
            end_time: Time.zone.parse("11:30"),
          )
        end

        let!(:court_only_booking) do
          create(
            :match,
            court: active_court,
            creator: player,
            time_slot: slot,
            date: schedule_date.in_time_zone.change(hour: 10),
            status: :confirmed,
            player_booking: true,
            walk_in: false,
          )
        end

        let!(:scheduled_match) do
          create(
            :match,
            court: court_b,
            creator: player,
            time_slot: slot_b,
            date: schedule_date.in_time_zone.change(hour: 10),
            status: :open,
            player_booking: false,
            walk_in: false,
          )
        end

        run_test! do |response|
          body = JSON.parse(response.body)
          court_only = body["cells"].find do |cell|
            cell["court_id"] == active_court.id && cell["start_time"] == "10:00"
          end
          expect(court_only["state"]).to eq("booked")
          expect(court_only).not_to have_key("match_id")

          with_match = body["cells"].find do |cell|
            cell["court_id"] == court_b.id && cell["start_time"] == "10:00"
          end
          expect(with_match["state"]).to eq("booked")
          expect(with_match["match_id"]).to eq(scheduled_match.id)
        end
      end

      response(403, "returns 403 without player role") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(owner)["Authorization"] }
        let(:id) { club.id }

        run_test!
      end

      response(422, "returns 422 when date is missing") do
        schema "$ref" => "#/components/schemas/Error"

        let(:Authorization) { auth_headers_for(player)["Authorization"] }
        let(:id) { club.id }
        let(:date) { nil }

        run_test!
      end
    end
  end
end
