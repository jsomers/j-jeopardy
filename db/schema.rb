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

ActiveRecord::Schema.define(:version => 20100224223918) do

  create_table "categories", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "name"
    t.integer  "q_count",    :default => 0
  end

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
    t.text    "single_table"
    t.text    "double_table"
    t.text    "points"
    t.integer "game_id"
    t.integer "answered",     :default => 0
  end

  create_table "episodes_players", :id => false, :force => true do |t|
    t.integer "episode_id"
    t.integer "player_id"
  end

  create_table "games", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "season"
    t.text     "categories"
    t.text     "airdate"
    t.integer  "game_id"
    t.text     "metadata"
    t.integer  "q_count",    :default => 0
  end

  add_index "games", ["game_id"], :name => "index_games_on_game_id", :unique => true

  create_table "guesses", :force => true do |t|
    t.integer  "question_id"
    t.string   "guess"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "player_id"
    t.string   "source",      :default => "regular"
  end

  create_table "players", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
  end

  create_table "questions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id"
    t.text     "question"
    t.text     "answer"
    t.text     "value"
    t.text     "coord"
    t.boolean  "fj",          :default => false
    t.integer  "category_id"
  end

  create_table "questionsets", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "q_ids"
  end

  create_table "seasons", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "n_games"
  end

  create_table "wagers", :force => true do |t|
    t.integer "my_score"
    t.text    "their_scores"
    t.integer "question_id"
    t.integer "player_id"
    t.integer "amount"
  end

end
