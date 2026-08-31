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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_000001) do
  create_table "cycles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.date "starts_on", null: false
    t.datetime "updated_at", null: false
    t.integer "world_cup_year"
    t.index ["slug"], name: "index_cycles_on_slug", unique: true
    t.index ["starts_on"], name: "index_cycles_on_starts_on"
  end

  create_table "goals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "for_us", default: true, null: false
    t.integer "match_id", null: false
    t.integer "minute"
    t.boolean "own_goal", default: false, null: false
    t.boolean "penalty", default: false, null: false
    t.integer "player_id"
    t.string "scorer_name", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id"], name: "index_goals_on_match_id"
    t.index ["player_id"], name: "index_goals_on_player_id"
  end

  create_table "matches", force: :cascade do |t|
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.integer "cycle_id", null: false
    t.boolean "home", default: true, null: false
    t.boolean "neutral", default: false, null: false
    t.string "opponent", null: false
    t.integer "opponent_score", null: false
    t.date "played_on", null: false
    t.string "tournament", null: false
    t.datetime "updated_at", null: false
    t.integer "us_score", null: false
    t.index ["city", "country"], name: "index_matches_on_city_and_country"
    t.index ["cycle_id"], name: "index_matches_on_cycle_id"
    t.index ["opponent"], name: "index_matches_on_opponent"
    t.index ["played_on"], name: "index_matches_on_played_on"
    t.index ["tournament"], name: "index_matches_on_tournament"
  end

  create_table "players", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_players_on_name", unique: true
    t.index ["slug"], name: "index_players_on_slug", unique: true
  end

  add_foreign_key "goals", "matches"
  add_foreign_key "goals", "players"
  add_foreign_key "matches", "cycles"
end
