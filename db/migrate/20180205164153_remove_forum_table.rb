class RemoveForumTable < ActiveRecord::Migration
  def up
    drop_table :forums
  end

  def down
    create_table "forums", force: :cascade do |t|
      t.string  "name",             limit: 255
      t.string  "description",      limit: 255
      t.integer "topics_count",     limit: 4,     default: 0
      t.integer "posts_count",      limit: 4,     default: 0
      t.integer "position",         limit: 4
      t.text    "description_html", limit: 65535
    end
  end
end
