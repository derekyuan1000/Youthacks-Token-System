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

ActiveRecord::Schema[8.0].define(version: 2025_05_28_220925) do
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
    t.index ["admin_id"], name: "index_activities_on_admin_id"
    t.index ["subject_type", "subject_id"], name: "index_activities_on_subject"
  end

  create_table "admins", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

  create_table "participants", force: :cascade do |t|
    t.string "name"
    t.string "pronouns"
    t.date "date_of_birth"
    t.string "email"
    t.integer "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "address"
    t.string "phone"
    t.string "emergency_name"
    t.string "emergency_phone"
    t.boolean "consent"
    t.string "dietary"
    t.string "medical"
    t.boolean "active", default: true
    t.boolean "checked_in", default: false
    t.datetime "check_in_time"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.text "description"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.bigint "product_id", null: false
    t.integer "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admin_id"
    t.index ["participant_id"], name: "index_transactions_on_participant_id"
    t.index ["product_id"], name: "index_transactions_on_product_id"
  end

  add_foreign_key "activities", "admins"
  add_foreign_key "transactions", "participants"
  add_foreign_key "transactions", "products"
end
