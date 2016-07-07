# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160706220623) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: :cascade do |t|
    t.integer "foreign_document_id"
    t.string  "foreign_document_url"
    t.string  "html_url"
    t.string  "secret"
  end

  create_table "hacker_news_posts", force: :cascade do |t|
    t.integer "hn_id"
    t.string  "title"
    t.string  "url"
  end

  create_table "peru_quiosco_pubs", force: :cascade do |t|
    t.integer  "pq_firstpage_id"
    t.integer  "pub_size"
    t.string   "title"
    t.string   "product"
    t.datetime "pub_time"
  end

end
