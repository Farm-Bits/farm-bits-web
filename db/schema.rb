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

ActiveRecord::Schema[7.2].define(version: 2025_08_13_095154) do
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
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
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
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
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

  create_table "client_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "viewer"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "user_id"], name: "index_client_users_on_client_id_and_user_id", unique: true
    t.index ["client_id"], name: "index_client_users_on_client_id"
    t.index ["user_id"], name: "index_client_users_on_user_id"
  end

  create_table "clients", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.string "color", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_clients_on_subdomain", unique: true
  end

  create_table "device_type_measurement_subtypes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "device_type_id", null: false
    t.bigint "measurement_subtype_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_type_id"], name: "index_device_type_measurement_subtypes_on_device_type_id"
    t.index ["measurement_subtype_id"], name: "index_device_type_measurement_subtypes_on_measurement_subtype_id"
  end

  create_table "device_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "communication_type", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["communication_type"], name: "index_device_types_on_communication_type"
  end

  create_table "devices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "device_type_id", null: false
    t.bigint "interface_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_type_id"], name: "index_devices_on_device_type_id"
    t.index ["interface_id"], name: "index_devices_on_interface_id"
  end

  create_table "interface_registers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "interface_id", null: false
    t.bigint "register_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interface_id"], name: "index_interface_registers_on_interface_id"
    t.index ["register_id"], name: "index_interface_registers_on_register_id"
  end

  create_table "interfaces", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "communication_type", null: false
    t.bigint "register_id", null: false
    t.bigint "plc_version_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["communication_type"], name: "index_interfaces_on_communication_type"
    t.index ["plc_version_id"], name: "index_interfaces_on_plc_version_id"
    t.index ["register_id"], name: "index_interfaces_on_register_id"
  end

  create_table "invitations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "inviter_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.string "role", default: "viewer"
    t.integer "status", default: 0
    t.datetime "expired_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "email"], name: "index_invitations_on_client_id_and_email", unique: true
    t.index ["client_id"], name: "index_invitations_on_client_id"
    t.index ["inviter_id"], name: "index_invitations_on_inviter_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "measurement_points", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "measurement_subtype_id"
    t.text "description"
    t.integer "min_value"
    t.integer "max_value"
    t.bigint "device_id"
    t.bigint "segment_id"
    t.bigint "site_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_measurement_points_on_device_id"
    t.index ["measurement_subtype_id"], name: "index_measurement_points_on_measurement_subtype_id"
    t.index ["segment_id"], name: "index_measurement_points_on_segment_id"
    t.index ["site_id"], name: "index_measurement_points_on_site_id"
  end

  create_table "measurement_subtypes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "value_type", null: false
    t.string "chart_type", null: false
    t.string "unit", null: false
    t.bigint "measurement_type_id"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["measurement_type_id"], name: "index_measurement_subtypes_on_measurement_type_id"
    t.index ["value_type"], name: "index_measurement_subtypes_on_value_type"
  end

  create_table "measurement_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plc_manufacturers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plc_models", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "plc_manufacturer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plc_manufacturer_id"], name: "index_plc_models_on_plc_manufacturer_id"
  end

  create_table "plc_versions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "plc_model_id"
    t.bigint "plc_version_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plc_model_id"], name: "index_plc_versions_on_plc_model_id"
    t.index ["plc_version_id"], name: "index_plc_versions_on_plc_version_id"
  end

  create_table "plcs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "plc_version_id", null: false
    t.integer "slave", null: false
    t.bigint "terminal_id"
    t.string "host"
    t.integer "port"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plc_version_id"], name: "index_plcs_on_plc_version_id"
    t.index ["terminal_id"], name: "index_plcs_on_terminal_id"
  end

  create_table "registers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "address", null: false
    t.integer "min_value"
    t.bigint "max_value"
    t.bigint "plc_version_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plc_version_id"], name: "index_registers_on_plc_version_id"
  end

  create_table "segments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "site_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_segments_on_site_id"
  end

  create_table "site_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "viewer"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "user_id"], name: "index_site_users_on_site_id_and_user_id", unique: true
    t.index ["site_id"], name: "index_site_users_on_site_id"
    t.index ["user_id"], name: "index_site_users_on_user_id"
  end

  create_table "sites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "country", null: false
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.float "altitude"
    t.bigint "client_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_sites_on_client_id"
  end

  create_table "terminal_manufacturers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terminal_models", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "terminal_manufacturer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["terminal_manufacturer_id"], name: "index_terminal_models_on_terminal_manufacturer_id"
  end

  create_table "terminals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "terminal_model_id"
    t.string "imei", null: false
    t.string "iccid", null: false
    t.string "phone_number", null: false
    t.bigint "site_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_terminals_on_site_id"
    t.index ["terminal_model_id"], name: "index_terminals_on_terminal_model_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
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
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "client_users", "clients", on_delete: :cascade
  add_foreign_key "client_users", "users", on_delete: :cascade
  add_foreign_key "device_type_measurement_subtypes", "device_types", on_delete: :cascade
  add_foreign_key "device_type_measurement_subtypes", "measurement_subtypes", on_delete: :cascade
  add_foreign_key "devices", "device_types"
  add_foreign_key "devices", "interfaces"
  add_foreign_key "interface_registers", "interfaces", on_delete: :cascade
  add_foreign_key "interface_registers", "registers", on_delete: :cascade
  add_foreign_key "interfaces", "plc_versions", on_delete: :cascade
  add_foreign_key "interfaces", "registers", on_delete: :cascade
  add_foreign_key "invitations", "clients", on_delete: :cascade
  add_foreign_key "invitations", "users", column: "inviter_id", on_delete: :cascade
  add_foreign_key "measurement_points", "devices", on_delete: :cascade
  add_foreign_key "measurement_points", "measurement_subtypes"
  add_foreign_key "measurement_points", "segments", on_delete: :cascade
  add_foreign_key "measurement_points", "sites", on_delete: :cascade
  add_foreign_key "measurement_subtypes", "measurement_types", on_delete: :cascade
  add_foreign_key "plc_models", "plc_manufacturers", on_delete: :cascade
  add_foreign_key "plc_versions", "plc_models", on_delete: :cascade
  add_foreign_key "plc_versions", "plc_versions", on_delete: :cascade
  add_foreign_key "plcs", "plc_versions"
  add_foreign_key "plcs", "terminals", on_delete: :cascade
  add_foreign_key "registers", "plc_versions", on_delete: :cascade
  add_foreign_key "segments", "sites", on_delete: :cascade
  add_foreign_key "site_users", "sites", on_delete: :cascade
  add_foreign_key "site_users", "users", on_delete: :cascade
  add_foreign_key "sites", "clients", on_delete: :cascade
  add_foreign_key "terminal_models", "terminal_manufacturers", on_delete: :cascade
  add_foreign_key "terminals", "sites", on_delete: :cascade
  add_foreign_key "terminals", "terminal_models"
end
