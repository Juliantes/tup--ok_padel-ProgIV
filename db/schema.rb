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

ActiveRecord::Schema[8.1].define(version: 2026_09_24_223000) do
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
    t.check_constraint "status = ANY (ARRAY[0, 1, 2])", name: "match_players_status_range"
    t.check_constraint "team IS NULL OR (team = ANY (ARRAY[1, 2]))", name: "match_players_team_range"
  end

  create_table "match_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "forced_by_admin", default: false, null: false
    t.bigint "match_id", null: false
    t.bigint "reported_by_id", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "reported_by_id"], name: "index_match_results_on_match_and_reporter", unique: true
    t.index ["reported_by_id"], name: "index_match_results_on_reported_by_id"
  end

  create_table "match_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_result_id", null: false
    t.integer "order", null: false
    t.integer "team_a_games", null: false
    t.integer "team_b_games", null: false
    t.datetime "updated_at", null: false
    t.index ["match_result_id", "order"], name: "index_match_sets_on_match_result_id_and_order", unique: true
    t.index ["match_result_id"], name: "index_match_sets_on_match_result_id"
  end

  create_table "matches", force: :cascade do |t|
    t.datetime "auto_approved_at"
    t.integer "best_of", default: 3, null: false
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.datetime "date", null: false
    t.integer "duration", default: 90, null: false
    t.integer "level_required", default: 0, null: false
    t.integer "roster_mode", default: 0, null: false
    t.datetime "stats_applied_at"
    t.integer "status", default: 0, null: false
    t.bigint "time_slot_id"
    t.datetime "updated_at", null: false
    t.index ["court_id"], name: "index_matches_on_court_id"
    t.index ["creator_id"], name: "index_matches_on_creator_id"
    t.index ["date", "court_id"], name: "index_matches_on_date_and_court_id"
    t.index ["roster_mode"], name: "index_matches_on_roster_mode"
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

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.integer "completed_jobs", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.datetime "enqueued_at"
    t.datetime "failed_at"
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "finished_at"
    t.text "metadata"
    t.text "on_failure"
    t.text "on_finish"
    t.text "on_success"
    t.integer "total_jobs", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.bigint "batch_id"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
  add_foreign_key "match_results", "users", column: "reported_by_id"
  add_foreign_key "match_sets", "match_results"
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
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "time_slots", "courts"
  add_foreign_key "user_roles", "users"
end
