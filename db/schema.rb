# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090801205812) do

  create_table "completeness", :force => true do |t|
    t.integer "game_id"
    t.boolean "complete"
  end

  create_table "completes", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id"
    t.boolean  "complete"
  end

  create_table "episodes", :force => true do |t|
    t.string  "key"
    t.text    "single_table"
    t.text    "double_table"
    t.text    "points"
    t.text    "charts"
    t.integer "game_id"
    t.integer "answered",     :default => 0
  end

  create_table "games", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "season"
    t.text     "categories"
    t.text     "airdate"
    t.integer  "game_id"
    t.text     "metadata"
  end

  add_index "games", ["game_id"], :name => "index_games_on_game_id", :unique => true

  create_table "players", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "handle"
    t.string   "password"
    t.string   "salt"
  end

  create_table "questions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id"
    t.text     "question"
    t.text     "answer"
    t.text     "value"
    t.text     "coord"
    t.boolean  "fj",         :default => false
    t.text     "category"
  end

end
