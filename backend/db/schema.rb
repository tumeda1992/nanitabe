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

ActiveRecord::Schema[7.2].define(version: 2024_04_28_080754) do
  create_table "dish_evaluations", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "dish_id", null: false
    t.bigint "user_id", null: false
    t.float "score", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id"], name: "index_dish_evaluations_on_dish_id", unique: true
    t.index ["user_id"], name: "index_dish_evaluations_on_user_id"
  end

  create_table "dish_source_relations", id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "dish_id", null: false
    t.bigint "dish_source_id", null: false
    t.integer "recipe_book_page"
    t.string "recipe_website_url"
    t.string "recipe_source_memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id"], name: "index_dish_source_relations_on_dish_id", unique: true
    t.index ["dish_source_id"], name: "index_dish_source_relations_on_dish_source_id"
  end

  create_table "dish_sources", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "type", null: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dish_sources_on_user_id"
  end

  create_table "dish_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "dish_id", null: false
    t.bigint "user_id", null: false
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_content"
    t.index ["content"], name: "index_dish_tags_on_content"
    t.index ["dish_id"], name: "index_dish_tags_on_dish_id"
    t.index ["normalized_content"], name: "index_dish_tags_on_normalized_content"
    t.index ["user_id"], name: "index_dish_tags_on_user_id"
  end

  create_table "dishes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.integer "meal_position", null: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_name"
    t.index ["user_id"], name: "index_dishes_on_user_id"
  end

  create_table "login_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "jti"
    t.index ["confirmation_token"], name: "index_login_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_login_users_on_email", unique: true
    t.index ["jti"], name: "index_login_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_login_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_login_users_on_uid_and_provider", unique: true
    t.index ["user_id"], name: "index_login_users_on_user_id"
  end

  create_table "meals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.integer "meal_type", null: false
    t.bigint "dish_id", null: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dish_id"], name: "index_meals_on_dish_id"
    t.index ["user_id"], name: "index_meals_on_user_id"
  end

  create_table "normalize_words", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "entered_source", null: false
    t.string "entered_destination", null: false
    t.string "source", null: false
    t.string "destination", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source"], name: "index_normalize_words_on_source"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "id_param", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_param"], name: "index_users_on_id_param", unique: true
  end

  add_foreign_key "dish_evaluations", "dishes"
  add_foreign_key "dish_evaluations", "users"
  add_foreign_key "dish_source_relations", "dish_sources"
  add_foreign_key "dish_source_relations", "dishes"
  add_foreign_key "dish_sources", "users"
  add_foreign_key "dish_tags", "dishes"
  add_foreign_key "dish_tags", "users"
  add_foreign_key "dishes", "users"
  add_foreign_key "login_users", "users"
  add_foreign_key "meals", "dishes"
  add_foreign_key "meals", "users"
end
