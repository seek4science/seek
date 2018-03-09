class RemoveForumAttachmentTable < ActiveRecord::Migration
  def up
    drop_table :forum_attachments
  end

  def down
    create_table "forum_attachments", force: :cascade do |t|
      t.integer  "post_id",      limit: 4
      t.string   "title",        limit: 255
      t.string   "content_type", limit: 255
      t.string   "filename",     limit: 255
      t.integer  "size",         limit: 4
      t.integer  "db_file_id",   limit: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
