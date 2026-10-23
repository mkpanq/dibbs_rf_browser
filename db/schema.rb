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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_142606) do
  create_table "imported_files", force: :cascade do |t|
    t.date "file_date", null: false
    t.string "url"
    t.integer "rows_count", default: 0, null: false
    t.datetime "imported_at", null: false
    t.index ["file_date"], name: "index_imported_files_on_file_date", unique: true
  end

  create_table "rfqs", force: :cascade do |t|
    t.string "solicitation", null: false
    t.string "purchase_request", null: false
    t.string "nsn", null: false
    t.string "fsc"
    t.string "item_name"
    t.integer "quantity"
    t.string "unit"
    t.date "return_by"
    t.string "buyer"
    t.string "amsc"
    t.string "item_type"
    t.string "set_aside"
    t.integer "set_aside_pct"
    t.date "posted_on", null: false
    t.date "last_seen_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fsc", "return_by"], name: "index_rfqs_on_fsc_and_return_by"
    t.index ["posted_on"], name: "index_rfqs_on_posted_on"
    t.index ["quantity"], name: "index_rfqs_on_quantity"
    t.index ["return_by"], name: "index_rfqs_on_return_by"
    t.index ["set_aside", "return_by"], name: "index_rfqs_on_set_aside_and_return_by"
    t.index ["solicitation", "purchase_request"], name: "index_rfqs_on_solicitation_and_purchase_request", unique: true
  end

  create_table "sync_runs", force: :cascade do |t|
    t.string "status", default: "running", null: false
    t.text "message"
    t.integer "files_count", default: 0, null: false
    t.integer "rows_count", default: 0, null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
  end
end
