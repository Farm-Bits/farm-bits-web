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

ActiveRecord::Schema[7.2].define(version: 2026_05_06_150135) do
  create_table "action_mailbox_inbound_emails", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "otp_enabled_at"
    t.json "otp_backup_codes_digests"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_admin_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["otp_enabled_at"], name: "index_admin_users_on_otp_enabled_at"
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
  end

  create_table "alert_candidates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "alert_rule_id", null: false
    t.datetime "predicate_first_true_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_rule_id"], name: "index_alert_candidates_on_alert_rule_id", unique: true
  end

  create_table "alert_rules", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "severity", null: false
    t.string "condition_type", null: false
    t.string "direction"
    t.decimal "threshold_value", precision: 15, scale: 6
    t.integer "inactivity_seconds"
    t.integer "min_duration_seconds"
    t.boolean "active", default: true, null: false
    t.bigint "measurement_point_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_type"], name: "index_alert_rules_on_condition_type"
    t.index ["measurement_point_id", "active"], name: "index_alert_rules_on_measurement_point_id_and_active"
    t.index ["measurement_point_id"], name: "index_alert_rules_on_measurement_point_id"
  end

  create_table "alert_subscriptions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "scope_type", null: false
    t.bigint "scope_id", null: false
    t.bigint "user_id", null: false
    t.json "channels"
    t.string "min_severity", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope_type", "scope_id"], name: "index_alert_subscriptions_on_scope"
    t.index ["user_id", "scope_type", "scope_id"], name: "idx_on_user_id_scope_type_scope_id_8cadbd77a1", unique: true
    t.index ["user_id"], name: "index_alert_subscriptions_on_user_id"
  end

  create_table "alerts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "rule_name", null: false
    t.string "severity", null: false
    t.string "condition_type", null: false
    t.string "direction"
    t.decimal "threshold_value", precision: 15, scale: 6
    t.integer "inactivity_seconds"
    t.integer "min_duration_seconds"
    t.string "measurement_point_name", null: false
    t.string "unit"
    t.string "segment_name", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.string "started_value"
    t.string "ended_value"
    t.bigint "measurement_point_id"
    t.bigint "alert_rule_id"
    t.bigint "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_rule_id", "ended_at"], name: "index_alerts_on_alert_rule_id_and_ended_at"
    t.index ["alert_rule_id"], name: "index_alerts_on_alert_rule_id"
    t.index ["ended_at", "started_at"], name: "index_alerts_on_ended_at_and_started_at"
    t.index ["measurement_point_id", "ended_at"], name: "index_alerts_on_measurement_point_id_and_ended_at"
    t.index ["measurement_point_id"], name: "index_alerts_on_measurement_point_id"
    t.index ["severity"], name: "index_alerts_on_severity"
    t.index ["site_id"], name: "index_alerts_on_site_id"
  end

  create_table "archived_hourly_aggregations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "hour_timestamp", null: false
    t.string "value_type", null: false
    t.integer "reading_count", default: 0, null: false
    t.decimal "start_value", precision: 20, scale: 6
    t.decimal "end_value", precision: 20, scale: 6
    t.decimal "delta", precision: 20, scale: 6
    t.decimal "min_value", precision: 20, scale: 6
    t.decimal "max_value", precision: 20, scale: 6
    t.decimal "avg_value", precision: 20, scale: 6
    t.decimal "sum_value", precision: 20, scale: 6
    t.integer "time_on_seconds"
    t.integer "time_off_seconds"
    t.integer "transition_count"
    t.datetime "first_reading_at"
    t.datetime "last_reading_at"
    t.bigint "measurement_point_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hour_timestamp"], name: "index_archived_hourly_aggregations_on_hour_timestamp"
    t.index ["measurement_point_id", "hour_timestamp"], name: "idx_on_measurement_point_id_hour_timestamp_0d2d8f84a8", unique: true
    t.index ["measurement_point_id"], name: "index_archived_hourly_aggregations_on_measurement_point_id"
  end

  create_table "archived_plc_write_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "source", null: false
    t.string "old_value"
    t.string "new_value"
    t.string "batch_id", null: false
    t.bigint "measurement_point_id", null: false
    t.bigint "plc_id", null: false
    t.bigint "site_id", null: false
    t.bigint "user_id"
    t.bigint "register_template_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_archived_plc_write_logs_on_batch_id"
    t.index ["created_at"], name: "index_archived_plc_write_logs_on_created_at"
    t.index ["measurement_point_id", "created_at"], name: "idx_on_measurement_point_id_created_at_4aacf7b684"
    t.index ["measurement_point_id"], name: "index_archived_plc_write_logs_on_measurement_point_id"
    t.index ["plc_id", "created_at"], name: "index_archived_plc_write_logs_on_plc_id_and_created_at"
    t.index ["plc_id"], name: "index_archived_plc_write_logs_on_plc_id"
    t.index ["register_template_id"], name: "index_archived_plc_write_logs_on_register_template_id"
    t.index ["site_id"], name: "index_archived_plc_write_logs_on_site_id"
    t.index ["source"], name: "index_archived_plc_write_logs_on_source"
    t.index ["user_id"], name: "index_archived_plc_write_logs_on_user_id"
  end

  create_table "archived_raw_values", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "value", precision: 20, scale: 6, null: false
    t.decimal "scaled_value", precision: 20, scale: 6, null: false
    t.datetime "sample_time", null: false
    t.bigint "measurement_point_id", null: false
    t.datetime "created_at", null: false
    t.index ["measurement_point_id", "sample_time"], name: "idx_on_measurement_point_id_sample_time_b3c8b16389"
    t.index ["measurement_point_id"], name: "index_archived_raw_values_on_measurement_point_id"
    t.index ["sample_time"], name: "index_archived_raw_values_on_sample_time"
  end

  create_table "archived_weather_station_api_hourly_aggregations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "weather_station_api_location_id", null: false
    t.bigint "weather_station_api_metric_id", null: false
    t.datetime "hour_timestamp", null: false
    t.decimal "min_value", precision: 15, scale: 4
    t.decimal "max_value", precision: 15, scale: 4
    t.decimal "avg_value", precision: 15, scale: 4
    t.decimal "sum_value", precision: 15, scale: 4
    t.integer "sample_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hour_timestamp"], name: "idx_on_hour_timestamp_6244ee0687"
    t.index ["weather_station_api_location_id", "weather_station_api_metric_id", "hour_timestamp"], name: "idx_on_weather_station_api_location_id_weather_stat_0147bc6245", unique: true
    t.index ["weather_station_api_location_id"], name: "idx_on_weather_station_api_location_id_daeffad96f"
    t.index ["weather_station_api_metric_id"], name: "idx_on_weather_station_api_metric_id_c0997e7704"
  end

  create_table "archived_weather_station_api_raw_values", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "weather_station_api_location_id", null: false
    t.bigint "weather_station_api_metric_id", null: false
    t.decimal "value", precision: 15, scale: 4, null: false
    t.decimal "scaled_value", precision: 15, scale: 4, null: false
    t.datetime "sample_time", null: false
    t.datetime "created_at", null: false
    t.index ["sample_time"], name: "index_archived_weather_station_api_raw_values_on_sample_time"
    t.index ["weather_station_api_location_id", "weather_station_api_metric_id", "sample_time"], name: "idx_on_weather_station_api_location_id_weather_stat_e16954371e", unique: true
    t.index ["weather_station_api_location_id"], name: "idx_on_weather_station_api_location_id_669a38b334"
    t.index ["weather_station_api_metric_id"], name: "idx_on_weather_station_api_metric_id_904dffbaac"
  end

  create_table "audits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "companies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "color", null: false
    t.boolean "require_2fa", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "company_user_sites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "company_user_id", null: false
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_user_id", "site_id"], name: "index_company_user_sites_on_company_user_id_and_site_id", unique: true
    t.index ["company_user_id"], name: "index_company_user_sites_on_company_user_id"
    t.index ["site_id"], name: "index_company_user_sites_on_site_id"
  end

  create_table "company_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "viewer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "user_id"], name: "index_company_users_on_company_id_and_user_id", unique: true
    t.index ["company_id"], name: "index_company_users_on_company_id"
    t.index ["user_id"], name: "index_company_users_on_user_id"
  end

  create_table "control_groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon_key"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gateways", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "label", null: false
    t.string "name", null: false
    t.string "imei", null: false
    t.string "serial_number", null: false
    t.string "iccid", null: false
    t.string "phone_number", null: false
    t.string "private_ip", null: false
    t.string "username", null: false
    t.text "password", null: false
    t.datetime "last_seen_at"
    t.boolean "active", default: true, null: false
    t.bigint "model_id", null: false
    t.bigint "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_gateways_on_active"
    t.index ["iccid"], name: "index_gateways_on_iccid", unique: true
    t.index ["imei"], name: "index_gateways_on_imei", unique: true
    t.index ["label"], name: "index_gateways_on_label", unique: true
    t.index ["model_id"], name: "index_gateways_on_model_id"
    t.index ["phone_number"], name: "index_gateways_on_phone_number", unique: true
    t.index ["serial_number"], name: "index_gateways_on_serial_number", unique: true
    t.index ["site_id", "active"], name: "index_gateways_on_site_id_and_active"
    t.index ["site_id"], name: "index_gateways_on_site_id"
  end

  create_table "hourly_aggregations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "hour_timestamp", null: false
    t.string "value_type", null: false
    t.integer "reading_count", default: 0, null: false
    t.decimal "start_value", precision: 20, scale: 6
    t.decimal "end_value", precision: 20, scale: 6
    t.decimal "delta", precision: 20, scale: 6
    t.decimal "min_value", precision: 20, scale: 6
    t.decimal "max_value", precision: 20, scale: 6
    t.decimal "avg_value", precision: 20, scale: 6
    t.decimal "sum_value", precision: 20, scale: 6
    t.integer "time_on_seconds"
    t.integer "time_off_seconds"
    t.integer "transition_count"
    t.datetime "first_reading_at"
    t.datetime "last_reading_at"
    t.bigint "measurement_point_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hour_timestamp"], name: "index_hourly_aggregations_on_hour_timestamp"
    t.index ["measurement_point_id", "hour_timestamp"], name: "idx_on_measurement_point_id_hour_timestamp_807c0aeea6", unique: true
    t.index ["measurement_point_id"], name: "index_hourly_aggregations_on_measurement_point_id"
  end

  create_table "interface_register_mappings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "description"
    t.integer "position", default: 0, null: false
    t.bigint "interface_id", null: false
    t.bigint "register_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interface_id", "position"], name: "index_interface_register_mappings_on_interface_id_and_position"
    t.index ["interface_id"], name: "index_interface_register_mappings_on_interface_id"
    t.index ["register_template_id"], name: "index_interface_register_mappings_on_register_template_id"
  end

  create_table "interfaces", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "communication_type", null: false
    t.text "description"
    t.integer "io_number", null: false
    t.bigint "modbus_firmware_version_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["modbus_firmware_version_id", "communication_type"], name: "idx_on_modbus_firmware_version_id_communication_typ_60c6b69306"
    t.index ["modbus_firmware_version_id", "io_number"], name: "index_interfaces_on_modbus_firmware_version_id_and_io_number"
    t.index ["modbus_firmware_version_id", "name"], name: "index_interfaces_on_modbus_firmware_version_id_and_name", unique: true
    t.index ["modbus_firmware_version_id"], name: "index_interfaces_on_modbus_firmware_version_id"
  end

  create_table "invitation_sites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "invitation_id", null: false
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitation_id", "site_id"], name: "index_invitation_sites_on_invitation_id_and_site_id", unique: true
    t.index ["invitation_id"], name: "index_invitation_sites_on_invitation_id"
    t.index ["site_id"], name: "index_invitation_sites_on_site_id"
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "role"
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.string "inviter_type", null: false
    t.bigint "inviter_id", null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "email"], name: "index_invitations_on_company_id_and_email", unique: true
    t.index ["company_id"], name: "index_invitations_on_company_id"
    t.index ["email", "inviter_type"], name: "index_invitations_on_email_and_inviter_type"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["inviter_type", "inviter_id"], name: "index_invitations_on_inviter"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "manufacturers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_manufacturers_on_name", unique: true
  end

  create_table "measurement_points", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "unit_override"
    t.string "chart_type_override"
    t.string "color_override"
    t.boolean "data_collection_enabled", default: false, null: false
    t.integer "polling_interval_seconds"
    t.decimal "factor_override", precision: 15, scale: 10
    t.decimal "offset_override", precision: 15, scale: 6
    t.string "last_decoded_value"
    t.datetime "last_decoded_value_at"
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.bigint "measurement_subtype_id"
    t.bigint "register_template_id", null: false
    t.bigint "plc_id"
    t.bigint "modbus_device_id"
    t.bigint "segment_id"
    t.bigint "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_measurement_points_on_active"
    t.index ["data_collection_enabled"], name: "index_measurement_points_on_data_collection_enabled"
    t.index ["measurement_subtype_id"], name: "index_measurement_points_on_measurement_subtype_id"
    t.index ["modbus_device_id"], name: "index_measurement_points_on_modbus_device_id"
    t.index ["plc_id", "data_collection_enabled"], name: "index_measurement_points_on_plc_id_and_data_collection_enabled"
    t.index ["plc_id", "position"], name: "index_measurement_points_on_plc_id_and_position"
    t.index ["plc_id", "register_template_id"], name: "index_measurement_points_on_plc_id_and_register_template_id", unique: true
    t.index ["plc_id"], name: "index_measurement_points_on_plc_id"
    t.index ["register_template_id"], name: "index_measurement_points_on_register_template_id"
    t.index ["segment_id"], name: "index_measurement_points_on_segment_id"
    t.index ["site_id"], name: "index_measurement_points_on_site_id"
  end

  create_table "measurement_subtypes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "data_category", null: false
    t.string "value_type", null: false
    t.bigint "control_group_id"
    t.string "default_unit", null: false
    t.string "default_chart_type", null: false
    t.string "default_color"
    t.string "icon_key"
    t.integer "position", default: 0, null: false
    t.bigint "measurement_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_group_id"], name: "index_measurement_subtypes_on_control_group_id"
    t.index ["data_category"], name: "index_measurement_subtypes_on_data_category"
    t.index ["measurement_type_id", "name"], name: "index_measurement_subtypes_on_measurement_type_id_and_name", unique: true
    t.index ["measurement_type_id", "position"], name: "index_measurement_subtypes_on_measurement_type_id_and_position"
    t.index ["measurement_type_id"], name: "index_measurement_subtypes_on_measurement_type_id"
    t.index ["value_type"], name: "index_measurement_subtypes_on_value_type"
  end

  create_table "measurement_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_measurement_types_on_name", unique: true
  end

  create_table "modbus_devices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "label"
    t.integer "slave_id", null: false
    t.string "private_ip"
    t.integer "slot_number"
    t.datetime "last_seen_at"
    t.boolean "active", default: true, null: false
    t.bigint "model_id", null: false
    t.bigint "modbus_firmware_version_id", null: false
    t.bigint "plc_id"
    t.bigint "gateway_id"
    t.bigint "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gateway_id", "private_ip"], name: "index_modbus_devices_on_gateway_id_and_private_ip", unique: true
    t.index ["gateway_id"], name: "index_modbus_devices_on_gateway_id"
    t.index ["modbus_firmware_version_id"], name: "index_modbus_devices_on_modbus_firmware_version_id"
    t.index ["model_id"], name: "index_modbus_devices_on_model_id"
    t.index ["plc_id", "slot_number"], name: "index_modbus_devices_on_plc_id_and_slot_number", unique: true
    t.index ["plc_id"], name: "index_modbus_devices_on_plc_id"
    t.index ["site_id"], name: "index_modbus_devices_on_site_id"
  end

  create_table "modbus_firmware_compatibilities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "host_version_id", null: false
    t.bigint "peripheral_version_id", null: false
    t.integer "firmware_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_version_id", "firmware_code"], name: "idx_on_host_version_id_firmware_code_a0c5a4bb26", unique: true
    t.index ["host_version_id", "peripheral_version_id"], name: "idx_on_host_version_id_peripheral_version_id_f74bc09a68", unique: true
    t.index ["host_version_id"], name: "index_modbus_firmware_compatibilities_on_host_version_id"
    t.index ["peripheral_version_id"], name: "index_modbus_firmware_compatibilities_on_peripheral_version_id"
  end

  create_table "modbus_firmware_relay_mappings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "modbus_firmware_version_id", null: false
    t.bigint "register_template_id", null: false
    t.integer "relay_offset", null: false
    t.string "direction", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["modbus_firmware_version_id", "register_template_id", "direction"], name: "idx_on_modbus_firmware_version_id_register_template_685faeeeb3", unique: true
    t.index ["modbus_firmware_version_id", "relay_offset"], name: "idx_on_modbus_firmware_version_id_relay_offset_d48dd4c6cf"
    t.index ["modbus_firmware_version_id"], name: "idx_on_modbus_firmware_version_id_05cabbf36f"
    t.index ["register_template_id"], name: "index_modbus_firmware_relay_mappings_on_register_template_id"
  end

  create_table "modbus_firmware_versions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "version_code", null: false
    t.string "behavior_profile"
    t.integer "relay_slot_base"
    t.integer "relay_slot_size"
    t.integer "relay_max_slots"
    t.string "relay_register_type"
    t.string "relay_read_strategy"
    t.text "description"
    t.boolean "is_latest", default: false, null: false
    t.boolean "is_supported", default: true, null: false
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["behavior_profile"], name: "index_modbus_firmware_versions_on_behavior_profile"
    t.index ["is_supported"], name: "index_modbus_firmware_versions_on_is_supported"
    t.index ["model_id", "is_latest"], name: "index_modbus_firmware_versions_on_model_id_and_is_latest"
    t.index ["model_id", "name"], name: "index_modbus_firmware_versions_on_model_id_and_name", unique: true
    t.index ["model_id"], name: "index_modbus_firmware_versions_on_model_id"
  end

  create_table "modbus_write_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "source", null: false
    t.string "old_value"
    t.string "new_value"
    t.string "batch_id", null: false
    t.bigint "measurement_point_id", null: false
    t.string "target_type", null: false
    t.integer "target_id", null: false
    t.bigint "relay_host_plc_id"
    t.bigint "site_id", null: false
    t.bigint "user_id"
    t.bigint "register_template_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_modbus_write_logs_on_batch_id"
    t.index ["created_at"], name: "index_modbus_write_logs_on_created_at"
    t.index ["created_at"], name: "index_modbus_write_logs_on_plc_id_and_created_at"
    t.index ["measurement_point_id", "created_at"], name: "index_modbus_write_logs_on_measurement_point_id_and_created_at"
    t.index ["measurement_point_id"], name: "index_modbus_write_logs_on_measurement_point_id"
    t.index ["register_template_id"], name: "index_modbus_write_logs_on_register_template_id"
    t.index ["relay_host_plc_id"], name: "index_modbus_write_logs_on_relay_host_plc_id"
    t.index ["site_id"], name: "index_modbus_write_logs_on_site_id"
    t.index ["source"], name: "index_modbus_write_logs_on_source"
    t.index ["target_type", "target_id"], name: "index_modbus_write_logs_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_modbus_write_logs_on_user_id"
  end

  create_table "models", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "device_type", null: false
    t.string "display_type"
    t.boolean "supports_modbus_tcp", default: false, null: false
    t.boolean "supports_modbus_rtu", default: false, null: false
    t.bigint "manufacturer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_type"], name: "index_models_on_device_type"
    t.index ["manufacturer_id", "name"], name: "index_models_on_manufacturer_id_and_name", unique: true
    t.index ["manufacturer_id"], name: "index_models_on_manufacturer_id"
  end

  create_table "plcs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "label", null: false
    t.string "name", null: false
    t.string "serial_number", null: false
    t.integer "slave_id", null: false
    t.string "private_ip"
    t.string "host"
    t.integer "port"
    t.string "username", null: false
    t.text "password", null: false
    t.string "web_username", null: false
    t.text "web_password", null: false
    t.datetime "last_seen_at"
    t.boolean "active", default: true, null: false
    t.bigint "model_id", null: false
    t.bigint "modbus_firmware_version_id", null: false
    t.bigint "gateway_id"
    t.bigint "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plcs_on_active"
    t.index ["gateway_id", "active"], name: "index_plcs_on_gateway_id_and_active"
    t.index ["gateway_id"], name: "index_plcs_on_gateway_id"
    t.index ["label"], name: "index_plcs_on_label", unique: true
    t.index ["modbus_firmware_version_id"], name: "index_plcs_on_modbus_firmware_version_id"
    t.index ["model_id"], name: "index_plcs_on_model_id"
    t.index ["serial_number"], name: "index_plcs_on_serial_number", unique: true
    t.index ["site_id"], name: "index_plcs_on_site_id"
    t.index ["username"], name: "index_plcs_on_username", unique: true
  end

  create_table "raw_values", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "value", precision: 20, scale: 6, null: false
    t.decimal "scaled_value", precision: 20, scale: 6, null: false
    t.datetime "sample_time", null: false
    t.bigint "measurement_point_id", null: false
    t.datetime "created_at", null: false
    t.index ["measurement_point_id", "sample_time"], name: "index_raw_values_on_measurement_point_id_and_sample_time"
    t.index ["measurement_point_id"], name: "index_raw_values_on_measurement_point_id"
    t.index ["sample_time"], name: "index_raw_values_on_sample_time"
  end

  create_table "register_templates", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "label", null: false
    t.text "description"
    t.integer "address", null: false
    t.integer "address_count", default: 1, null: false
    t.string "register_type", null: false
    t.string "data_type", null: false
    t.string "byte_order", null: false
    t.string "value_format", default: "numeric", null: false
    t.decimal "factor", precision: 15, scale: 10, default: "1.0", null: false
    t.decimal "offset", precision: 15, scale: 6, default: "0.0", null: false
    t.string "category", null: false
    t.string "group_name"
    t.string "group_role"
    t.json "validation_rules"
    t.json "visibility_conditions"
    t.string "bulk_read_group"
    t.integer "bulk_read_address"
    t.integer "bulk_read_offset"
    t.boolean "read_only", default: true, null: false
    t.string "user_visibility", null: false
    t.decimal "min_value", precision: 20, scale: 6
    t.decimal "max_value", precision: 20, scale: 6
    t.string "default_value"
    t.json "enum_values"
    t.json "read_only_enum_keys"
    t.integer "position", default: 0, null: false
    t.bigint "default_measurement_subtype_id"
    t.bigint "modbus_firmware_version_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_register_templates_on_category"
    t.index ["default_measurement_subtype_id"], name: "index_register_templates_on_default_measurement_subtype_id"
    t.index ["modbus_firmware_version_id", "bulk_read_group"], name: "idx_on_modbus_firmware_version_id_bulk_read_group_fec5f958f2"
    t.index ["modbus_firmware_version_id", "category"], name: "idx_on_modbus_firmware_version_id_category_fb2ebbd4fe"
    t.index ["modbus_firmware_version_id", "group_name"], name: "idx_on_modbus_firmware_version_id_group_name_444938a547"
    t.index ["modbus_firmware_version_id", "label"], name: "idx_on_modbus_firmware_version_id_label_1c522bb600", unique: true
    t.index ["modbus_firmware_version_id", "name"], name: "idx_on_modbus_firmware_version_id_name_cb822f8b8e"
    t.index ["modbus_firmware_version_id", "position"], name: "idx_on_modbus_firmware_version_id_position_06de66e444"
    t.index ["modbus_firmware_version_id", "register_type", "address"], name: "idx_on_modbus_firmware_version_id_register_type_add_eaaf00ae90", unique: true
    t.index ["modbus_firmware_version_id"], name: "index_register_templates_on_modbus_firmware_version_id"
  end

  create_table "segments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "name"], name: "index_segments_on_site_id_and_name", unique: true
    t.index ["site_id"], name: "index_segments_on_site_id"
  end

  create_table "site_sun_data", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "date", null: false
    t.time "sunrise", null: false
    t.time "sunset", null: false
    t.time "civil_twilight_begin"
    t.time "civil_twilight_end"
    t.integer "day_length_seconds"
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_site_sun_data_on_date"
    t.index ["site_id", "date"], name: "index_site_sun_data_on_site_id_and_date", unique: true
    t.index ["site_id"], name: "index_site_sun_data_on_site_id"
  end

  create_table "sites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "country", null: false
    t.string "city"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.decimal "geocoded_latitude", precision: 10, scale: 7
    t.decimal "geocoded_longitude", precision: 10, scale: 7
    t.string "time_zone", null: false
    t.bigint "weather_station_api_location_id"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_sites_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_sites_on_company_id"
    t.index ["weather_station_api_location_id"], name: "index_sites_on_weather_station_api_location_id"
  end

  create_table "user_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "transport", null: false
    t.string "remember_token_digest"
    t.string "jti"
    t.string "client_name"
    t.string "user_agent"
    t.string "ip_address"
    t.string "pending_otp_digest"
    t.integer "pending_otp_attempts", default: 0, null: false
    t.datetime "pending_otp_expires_at"
    t.datetime "last_seen_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "mfa_verified_at"
    t.bigint "current_company_id"
    t.string "authenticatable_type", null: false
    t.bigint "authenticatable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id", "revoked_at"], name: "idx_on_authenticatable_type_authenticatable_id_revo_f71e4a64ee"
    t.index ["authenticatable_type", "authenticatable_id"], name: "index_user_sessions_on_authenticatable"
    t.index ["current_company_id"], name: "index_user_sessions_on_current_company_id"
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["jti"], name: "index_user_sessions_on_jti", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "otp_enabled_at"
    t.json "otp_backup_codes_digests"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["otp_enabled_at"], name: "index_users_on_otp_enabled_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "weather_station_api_hourly_aggregations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "weather_station_api_location_id", null: false
    t.bigint "weather_station_api_metric_id", null: false
    t.datetime "hour_timestamp", null: false
    t.decimal "min_value", precision: 15, scale: 4
    t.decimal "max_value", precision: 15, scale: 4
    t.decimal "avg_value", precision: 15, scale: 4
    t.decimal "sum_value", precision: 15, scale: 4
    t.integer "sample_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hour_timestamp"], name: "idx_on_hour_timestamp_c177ed907d"
    t.index ["weather_station_api_location_id", "weather_station_api_metric_id", "hour_timestamp"], name: "idx_on_weather_station_api_location_id_weather_stat_865b63851a", unique: true
    t.index ["weather_station_api_location_id"], name: "idx_on_weather_station_api_location_id_e0db279935"
    t.index ["weather_station_api_metric_id"], name: "idx_on_weather_station_api_metric_id_eec1d9eb85"
  end

  create_table "weather_station_api_locations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.string "provider", null: false
    t.json "provider_config"
    t.string "time_zone", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_fetched_at"
    t.integer "fetch_interval_minutes", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_weather_station_api_locations_on_latitude_and_longitude"
    t.index ["provider"], name: "index_weather_station_api_locations_on_provider"
  end

  create_table "weather_station_api_metrics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "label", null: false
    t.string "unit", null: false
    t.decimal "factor", precision: 15, scale: 6, default: "1.0", null: false
    t.decimal "offset", precision: 15, scale: 6, default: "0.0", null: false
    t.bigint "measurement_subtype_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_weather_station_api_metrics_on_key", unique: true
    t.index ["measurement_subtype_id"], name: "index_weather_station_api_metrics_on_measurement_subtype_id"
  end

  create_table "weather_station_api_raw_values", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "weather_station_api_location_id", null: false
    t.bigint "weather_station_api_metric_id", null: false
    t.decimal "value", precision: 15, scale: 4, null: false
    t.decimal "scaled_value", precision: 15, scale: 4, null: false
    t.datetime "sample_time", null: false
    t.datetime "created_at", null: false
    t.index ["sample_time"], name: "index_weather_station_api_raw_values_on_sample_time"
    t.index ["weather_station_api_location_id", "weather_station_api_metric_id", "sample_time"], name: "idx_on_weather_station_api_location_id_weather_stat_4e4f832263", unique: true
    t.index ["weather_station_api_location_id"], name: "idx_on_weather_station_api_location_id_1061f2324a"
    t.index ["weather_station_api_metric_id"], name: "idx_on_weather_station_api_metric_id_5188e0edb2"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "alert_candidates", "alert_rules", on_delete: :cascade
  add_foreign_key "alert_rules", "measurement_points", on_delete: :cascade
  add_foreign_key "alert_subscriptions", "users", on_delete: :cascade
  add_foreign_key "alerts", "alert_rules", on_delete: :nullify
  add_foreign_key "alerts", "measurement_points", on_delete: :nullify
  add_foreign_key "alerts", "sites", on_delete: :nullify
  add_foreign_key "archived_hourly_aggregations", "measurement_points", on_delete: :cascade
  add_foreign_key "archived_plc_write_logs", "measurement_points", on_delete: :cascade
  add_foreign_key "archived_plc_write_logs", "plcs", on_delete: :cascade
  add_foreign_key "archived_plc_write_logs", "register_templates", on_delete: :cascade
  add_foreign_key "archived_plc_write_logs", "sites", on_delete: :cascade
  add_foreign_key "archived_plc_write_logs", "users", on_delete: :nullify
  add_foreign_key "archived_raw_values", "measurement_points", on_delete: :cascade
  add_foreign_key "archived_weather_station_api_hourly_aggregations", "weather_station_api_locations", on_delete: :cascade
  add_foreign_key "archived_weather_station_api_hourly_aggregations", "weather_station_api_metrics", on_delete: :cascade
  add_foreign_key "archived_weather_station_api_raw_values", "weather_station_api_locations", on_delete: :cascade
  add_foreign_key "archived_weather_station_api_raw_values", "weather_station_api_metrics", on_delete: :cascade
  add_foreign_key "company_user_sites", "company_users", on_delete: :cascade
  add_foreign_key "company_user_sites", "sites", on_delete: :cascade
  add_foreign_key "company_users", "companies", on_delete: :cascade
  add_foreign_key "company_users", "users", on_delete: :cascade
  add_foreign_key "gateways", "models"
  add_foreign_key "gateways", "sites"
  add_foreign_key "hourly_aggregations", "measurement_points", on_delete: :cascade
  add_foreign_key "interface_register_mappings", "interfaces", on_delete: :cascade
  add_foreign_key "interface_register_mappings", "register_templates", on_delete: :cascade
  add_foreign_key "interfaces", "modbus_firmware_versions", on_delete: :cascade
  add_foreign_key "invitation_sites", "invitations"
  add_foreign_key "invitation_sites", "sites"
  add_foreign_key "invitations", "companies", on_delete: :cascade
  add_foreign_key "measurement_points", "measurement_subtypes", on_delete: :cascade
  add_foreign_key "measurement_points", "modbus_devices", on_delete: :cascade
  add_foreign_key "measurement_points", "plcs", on_delete: :cascade
  add_foreign_key "measurement_points", "register_templates", on_delete: :cascade
  add_foreign_key "measurement_points", "segments", on_delete: :cascade
  add_foreign_key "measurement_points", "sites", on_delete: :cascade
  add_foreign_key "measurement_subtypes", "control_groups", on_delete: :nullify
  add_foreign_key "measurement_subtypes", "measurement_types", on_delete: :cascade
  add_foreign_key "modbus_devices", "gateways"
  add_foreign_key "modbus_devices", "modbus_firmware_versions"
  add_foreign_key "modbus_devices", "models"
  add_foreign_key "modbus_devices", "plcs"
  add_foreign_key "modbus_devices", "sites"
  add_foreign_key "modbus_firmware_compatibilities", "modbus_firmware_versions", column: "host_version_id", on_delete: :cascade
  add_foreign_key "modbus_firmware_compatibilities", "modbus_firmware_versions", column: "peripheral_version_id", on_delete: :cascade
  add_foreign_key "modbus_firmware_relay_mappings", "modbus_firmware_versions", on_delete: :cascade
  add_foreign_key "modbus_firmware_relay_mappings", "register_templates", on_delete: :cascade
  add_foreign_key "modbus_firmware_versions", "models", on_delete: :cascade
  add_foreign_key "modbus_write_logs", "measurement_points", on_delete: :cascade
  add_foreign_key "modbus_write_logs", "plcs", column: "relay_host_plc_id"
  add_foreign_key "modbus_write_logs", "register_templates", on_delete: :cascade
  add_foreign_key "modbus_write_logs", "sites", on_delete: :cascade
  add_foreign_key "modbus_write_logs", "users", on_delete: :nullify
  add_foreign_key "models", "manufacturers", on_delete: :cascade
  add_foreign_key "plcs", "gateways"
  add_foreign_key "plcs", "modbus_firmware_versions"
  add_foreign_key "plcs", "models"
  add_foreign_key "plcs", "sites"
  add_foreign_key "raw_values", "measurement_points", on_delete: :cascade
  add_foreign_key "register_templates", "measurement_subtypes", column: "default_measurement_subtype_id", on_delete: :nullify
  add_foreign_key "register_templates", "modbus_firmware_versions", on_delete: :cascade
  add_foreign_key "segments", "sites", on_delete: :cascade
  add_foreign_key "site_sun_data", "sites", on_delete: :cascade
  add_foreign_key "sites", "companies", on_delete: :cascade
  add_foreign_key "sites", "weather_station_api_locations", on_delete: :nullify
  add_foreign_key "user_sessions", "companies", column: "current_company_id"
  add_foreign_key "weather_station_api_hourly_aggregations", "weather_station_api_locations", on_delete: :cascade
  add_foreign_key "weather_station_api_hourly_aggregations", "weather_station_api_metrics", on_delete: :cascade
  add_foreign_key "weather_station_api_metrics", "measurement_subtypes", on_delete: :cascade
  add_foreign_key "weather_station_api_raw_values", "weather_station_api_locations", on_delete: :cascade
  add_foreign_key "weather_station_api_raw_values", "weather_station_api_metrics", on_delete: :cascade
end
