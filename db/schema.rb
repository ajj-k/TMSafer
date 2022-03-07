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

ActiveRecord::Schema.define(version: 2022_03_07_055338) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "members", force: :cascade do |t|
    t.bigint "school_id"
    t.string "name"
    t.string "icon"
    t.string "url"
    t.string "cource"
    t.index ["school_id"], name: "index_members_on_school_id"
  end

  create_table "schools", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_schools_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "member_id"
    t.string "content"
    t.date "date"
    t.integer "importance"
    t.boolean "done"
    t.index ["member_id"], name: "index_tasks_on_member_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "mail"
    t.string "password_digest"
    t.string "icon"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "members", "schools"
  add_foreign_key "schools", "users"
  add_foreign_key "tasks", "members"
end
