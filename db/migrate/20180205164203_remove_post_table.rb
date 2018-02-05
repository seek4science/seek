class RemovePostTable < ActiveRecord::Migration
  def up
    drop_table :posts
  end

  def down
    create_table "posts", force: :cascade do |t|
      t.integer  "user_id",    limit: 4
      t.integer  "topic_id",   limit: 4
      t.text     "body",       limit: 65535
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "forum_id",   limit: 4
      t.text     "body_html",  limit: 65535
    end
  end
end
