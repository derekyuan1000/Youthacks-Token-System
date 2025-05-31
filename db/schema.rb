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

ActiveRecord::Schema[8.0].define(version: 2025_05_31_161316) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.string "action"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "admin_id", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.bigint "event_id"
    t.index ["admin_id"], name: "index_activities_on_admin_id"
    t.index ["event_id"], name: "index_activities_on_event_id"
    t.index ["subject_type", "subject_id"], name: "index_activities_on_subject"
  end

  create_table "admins", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "email"
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["name"], name: "index_admins_on_name", unique: true
  end

  create_table "event_admins", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "admin_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_event_admins_on_admin_id"
    t.index ["event_id"], name: "index_event_admins_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "manager_id", null: false
    t.string "airtable_api_key"
    t.string "airtable_base_id"
    t.string "airtable_table_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.string "id_column"
    t.string "slug"
    t.date "date"
    t.string "name_column"
    t.index ["manager_id"], name: "index_events_on_manager_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "participants", force: :cascade do |t|
    t.string "name"
    t.integer "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.boolean "checked_in", default: false
    t.datetime "check_in_time"
    t.json "personal_info"
    t.bigint "event_id"
    t.index ["event_id"], name: "index_participants_on_event_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.text "description"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_id"
    t.boolean "active"
    t.index ["event_id"], name: "index_products_on_event_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.bigint "product_id", null: false
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_id"
    t.bigint "event_id"
    t.index ["event_id"], name: "index_transactions_on_event_id"
    t.index ["participant_id"], name: "index_transactions_on_participant_id"
    t.index ["product_id"], name: "index_transactions_on_product_id"
  end

  add_foreign_key "activities", "admins"
  add_foreign_key "activities", "events"
  add_foreign_key "event_admins", "admins"
  add_foreign_key "event_admins", "events"
  add_foreign_key "events", "admins", column: "manager_id"
  add_foreign_key "participants", "events"
  add_foreign_key "products", "events"
  add_foreign_key "transactions", "events"
  add_foreign_key "transactions", "participants"
  add_foreign_key "transactions", "products"
end
