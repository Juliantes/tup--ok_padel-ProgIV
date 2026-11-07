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
