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

ActiveRecord::Schema.define(:version => 20081012155343) do

  create_table "groups", :force => true do |t|
    t.string   "group_name"
    t.string   "country"
    t.string   "city"
    t.text     "address"
    t.string   "web_page"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_projects", :id => false, :force => true do |t|
    t.integer "group_id",   :limit => 11
    t.integer "project_id", :limit => 11
  end

  create_table "people", :force => true do |t|
    t.string   "fist_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "skype_name"
    t.string   "web_page"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people_projects", :id => false, :force => true do |t|
    t.integer "person_id",  :limit => 11
    t.integer "project_id", :limit => 11
  end

  create_table "projects", :force => true do |t|
    t.string   "title"
    t.string   "web_page"
    t.string   "wiki_page"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
