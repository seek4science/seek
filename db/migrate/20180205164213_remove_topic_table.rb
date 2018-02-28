class RemoveTopicTable < ActiveRecord::Migration
  def up
    drop_table :topics
  end

  def down
    create_table "topics", force: :cascade do |t|
      t.integer  "forum_id",     limit: 4
      t.integer  "user_id",      limit: 4
      t.string   "title",        limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "hits",         limit: 4,   default: 0
      t.integer  "sticky",       limit: 4,   default: 0
      t.integer  "posts_count",  limit: 4,   default: 0
      t.datetime "replied_at"
      t.boolean  "locked",                   default: false
      t.integer  "replied_by",   limit: 4
      t.integer  "last_post_id", limit: 4
    end
  end
end
