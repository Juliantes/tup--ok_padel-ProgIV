# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Ok Padel API",
        version: "v1",
        description: "API REST JSON para jugadores (TP1 Programación IV)."
      },
      paths: {},
      servers: [
        { url: "http://localhost:3000" },
        { url: "https://ok-padel-tup.fly.dev" }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        },
        schemas: {
          Error: {
            type: :object,
            properties: {
              error: { type: :string },
              request_id: { type: :string, nullable: true },
              errors: {
                type: :object,
                additionalProperties: {
                  type: :array,
                  items: { type: :string }
                },
                nullable: true
              }
            },
            required: [ "error" ]
          },
          UnauthorizedError: {
            type: :object,
            description: "401 de autenticación JWT: token_missing, token_invalid o token_expired.",
            properties: {
              error: {
                type: :string,
                enum: %w[token_missing token_invalid token_expired]
              }
            },
            required: [ "error" ]
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email: { type: :string, format: :email },
              phone: { type: :string, nullable: true },
              self_level: { type: :integer },
              category_label: { type: :string },
              bio: { type: :string, nullable: true },
              average_level: { type: :string, nullable: true },
              average_stars: { type: :string, nullable: true },
              matches_played: { type: :integer }
            },
            required: %w[id name email self_level category_label matches_played]
          },
          LoginResponse: {
            type: :object,
            properties: {
              token: { type: :string },
              user: { "$ref" => "#/components/schemas/User" }
            },
            required: %w[token user]
          },
          UserResponse: {
            type: :object,
            properties: {
              user: { "$ref" => "#/components/schemas/User" }
            },
            required: [ "user" ]
          },
          ClubSummary: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              address: { type: :string, nullable: true }
            },
            required: %w[id name]
          },
          Court: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string, nullable: true },
              court_type: { type: :string, enum: %w[indoor outdoor] },
              price_per_hour: { type: :number },
              status: { type: :string, enum: %w[active maintenance inactive] },
              club: { "$ref" => "#/components/schemas/ClubSummary" },
              image_url: { type: :string, format: :uri, nullable: true }
            },
            required: %w[id name court_type price_per_hour status club]
          },
          CourtsResponse: {
            type: :object,
            properties: {
              courts: {
                type: :array,
                items: { "$ref" => "#/components/schemas/Court" }
              }
            },
            required: [ "courts" ]
          },
          CourtResponse: {
            type: :object,
            properties: {
              court: { "$ref" => "#/components/schemas/Court" }
            },
            required: [ "court" ]
          },
          MatchCourtSummary: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              club_id: { type: :integer }
            },
            required: %w[id name club_id]
          },
          MatchCreatorSummary: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string }
            },
            required: %w[id name]
          },
          MatchPlayer: {
            type: :object,
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              team: { type: :string, enum: %w[team_a team_b] },
              status: { type: :string, enum: %w[pending confirmed cancelled] },
              joined_at: { type: :string, format: "date-time", nullable: true },
              user: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  name: { type: :string }
                },
                required: %w[id name]
              }
            },
            required: %w[id user_id team status user]
          },
          TimeSlot: {
            type: :object,
            nullable: true,
            properties: {
              id: { type: :integer },
              day_of_week: { type: :integer },
              start_time: { type: :string, example: "10:00" },
              end_time: { type: :string, example: "11:30" },
              is_available: { type: :boolean }
            },
            required: %w[id day_of_week start_time end_time is_available]
          },
          MatchSet: {
            type: :object,
            properties: {
              order: { type: :integer },
              team_a_games: { type: :integer },
              team_b_games: { type: :integer }
            },
            required: %w[order team_a_games team_b_games]
          },
          MatchResultReporter: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string }
            },
            required: %w[id name]
          },
          MatchResult: {
            type: :object,
            properties: {
              id: { type: :integer },
              sets: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchSet" }
              },
              winner_team: { type: :string, enum: %w[team_a team_b], nullable: true },
              reported_by: { "$ref" => "#/components/schemas/MatchResultReporter" },
              created_at: { type: :string, format: "date-time" }
            },
            required: %w[id sets reported_by created_at]
          },
          Consensus: {
            type: :object,
            nullable: true,
            properties: {
              votes: { type: :integer },
              total: { type: :integer },
              signature: { type: :string },
              sets: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchSet" }
              }
            },
            required: %w[votes total signature sets]
          },
          Match: {
            type: :object,
            properties: {
              id: { type: :integer },
              date: { type: :string, format: "date-time" },
              duration: { type: :integer },
              status: {
                type: :string,
                enum: %w[open full confirmed completed cancelled reported]
              },
              roster_mode: { type: :string, enum: %w[pairs individual] },
              level_required: {
                type: :string,
                enum: %w[open eighth seventh sixth fifth fourth third second first]
              },
              join_policy: { type: :string, example: "auto" },
              court: { "$ref" => "#/components/schemas/MatchCourtSummary" },
              creator: { "$ref" => "#/components/schemas/MatchCreatorSummary" },
              match_players: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchPlayer" }
              },
              players_count: { type: :integer },
              max_players: { type: :integer },
              time_slot: { "$ref" => "#/components/schemas/TimeSlot" },
              match_results: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchResult" }
              },
              consensus: { "$ref" => "#/components/schemas/Consensus" }
            },
            required: %w[
              id date duration status roster_mode level_required join_policy
              court creator match_players players_count max_players
            ]
          },
          MatchResponse: {
            type: :object,
            properties: {
              match: { "$ref" => "#/components/schemas/Match" }
            },
            required: [ "match" ]
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              per_page: { type: :integer },
              total_pages: { type: :integer },
              total_count: { type: :integer }
            },
            required: %w[current_page per_page total_pages total_count]
          },
          MatchesResponse: {
            type: :object,
            properties: {
              matches: {
                type: :array,
                items: { "$ref" => "#/components/schemas/Match" }
              },
              meta: { "$ref" => "#/components/schemas/PaginationMeta" }
            },
            required: %w[matches meta]
          },
          MatchResultsIndexResponse: {
            type: :object,
            properties: {
              results: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchResult" }
              },
              consensus: { "$ref" => "#/components/schemas/Consensus" },
              total: { type: :integer }
            },
            required: %w[results total]
          },
          MatchResultsMutationResponse: {
            type: :object,
            properties: {
              match: { "$ref" => "#/components/schemas/Match" },
              results: {
                type: :array,
                items: { "$ref" => "#/components/schemas/MatchResult" }
              },
              consensus: { "$ref" => "#/components/schemas/Consensus" }
            },
            required: %w[match results]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
