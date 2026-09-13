# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_13_210000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clubs", force: :cascade do |t|
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_clubs_on_owner_id"
  end

  create_table "courts", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.integer "court_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "price_per_hour", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["club_id", "name"], name: "index_courts_on_club_id_and_name", unique: true
    t.index ["club_id"], name: "index_courts_on_club_id"
    t.check_constraint "price_per_hour > 0::numeric AND price_per_hour <= 99999999.99", name: "courts_price_per_hour_range"
  end

  create_table "match_players", force: :cascade do |t|
    t.bigint "approved_by_id"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "joined_at", default: -> { "CURRENT_TIMESTAMP" }
    t.bigint "match_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "team"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved_by_id"], name: "index_match_players_on_approved_by_id"
    t.index ["match_id", "user_id"], name: "index_match_players_on_match_id_and_user_id", unique: true
    t.index ["match_id"], name: "index_match_players_on_match_id"
    t.index ["user_id"], name: "index_match_players_on_user_id"
  end

  create_table "match_results", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.bigint "reported_by_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "team_a_score"
    t.integer "team_b_score"
    t.datetime "updated_at", null: false
    t.integer "winner_team"
    t.index ["approved_by_id"], name: "index_match_results_on_approved_by_id"
    t.index ["match_id"], name: "index_match_results_on_match_id", unique: true
    t.index ["reported_by_id"], name: "index_match_results_on_reported_by_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.datetime "date", null: false
    t.integer "duration", default: 90, null: false
    t.integer "level_required", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "time_slot_id"
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_matches_on_court_id"
    t.index ["creator_id"], name: "index_matches_on_creator_id"
    t.index ["date", "court_id"], name: "index_matches_on_date_and_court_id"
    t.index ["status"], name: "index_matches_on_status"
    t.index ["time_slot_id"], name: "index_matches_on_time_slot_id"
    t.check_constraint "duration > 0 AND duration <= 240", name: "matches_duration_range"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "is_group_chat", default: false, null: false
    t.bigint "match_id"
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.bigint "receiver_id"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_messages_on_match_id"
    t.index ["receiver_id"], name: "index_messages_on_receiver_id"
    t.index ["sender_id", "receiver_id"], name: "index_messages_on_sender_id_and_receiver_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "player_stats", force: :cascade do |t|
    t.integer "best_streak", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_streak", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "win_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "wins", default: 0, null: false
    t.index ["user_id"], name: "index_player_stats_on_user_id", unique: true
    t.check_constraint "win_rate >= 0::numeric AND win_rate <= 100::numeric", name: "player_stats_win_rate_range"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.boolean "is_upgradable", default: true, null: false
    t.integer "level_rating", null: false
    t.bigint "match_id", null: false
    t.bigint "reviewed_user_id", null: false
    t.bigint "reviewer_id", null: false
    t.integer "stars", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_reviews_on_match_id"
    t.index ["reviewed_user_id"], name: "index_reviews_on_reviewed_user_id"
    t.index ["reviewer_id", "reviewed_user_id", "match_id"], name: "index_reviews_unique_per_match", unique: true
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "time_slots", force: :cascade do |t|
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time", null: false
    t.boolean "is_available", default: true, null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["court_id", "day_of_week", "start_time", "end_time"], name: "index_time_slots_unique_per_court", unique: true
    t.index ["court_id"], name: "index_time_slots_on_court_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "role"], name: "index_user_roles_on_user_id_and_role", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "accepts_messages", default: true, null: false
    t.decimal "average_level", precision: 3, scale: 1, default: "0.0"
    t.decimal "average_stars", precision: 3, scale: 2, default: "0.0"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "matches_abandoned", default: 0, null: false
    t.integer "matches_cancelled", default: 0, null: false
    t.integer "matches_played", default: 0, null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "self_level", null: false
    t.integer "total_reviews", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "average_level >= 0::numeric AND average_level <= 99.9", name: "users_average_level_range"
    t.check_constraint "average_stars >= 0::numeric AND average_stars <= 9.99", name: "users_average_stars_range"
    t.check_constraint "self_level >= 1 AND self_level <= 8", name: "users_self_level_range"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "clubs", "users", column: "owner_id"
  add_foreign_key "courts", "clubs"
  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "users"
  add_foreign_key "match_players", "users", column: "approved_by_id"
  add_foreign_key "match_results", "matches"
  add_foreign_key "match_results", "users", column: "approved_by_id"
  add_foreign_key "match_results", "users", column: "reported_by_id"
  add_foreign_key "matches", "courts"
  add_foreign_key "matches", "time_slots"
  add_foreign_key "matches", "users", column: "creator_id"
  add_foreign_key "messages", "matches"
  add_foreign_key "messages", "users", column: "receiver_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "player_stats", "users"
  add_foreign_key "reviews", "matches"
  add_foreign_key "reviews", "users", column: "reviewed_user_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "time_slots", "courts"
  add_foreign_key "user_roles", "users"
end
