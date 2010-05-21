class CreateForumAttachments < ActiveRecord::Migration
  def self.up
    create_table :forum_attachments do |t|
      t.integer :post_id
      t.string :title
      t.string :content_type
      t.string :filename 
      t.integer :size
      t.integer :db_file_id
      t.timestamps
    end
  end

  def self.down
    drop_table :forum_attachments
  end
end
