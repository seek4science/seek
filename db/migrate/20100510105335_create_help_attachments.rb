class CreateHelpAttachments < ActiveRecord::Migration
  def self.up
    create_table :help_attachments do |t|
      t.integer :help_document_id
      t.string :title
      t.string :content_type
      t.string :filename 
      t.integer :size
      t.integer :db_file_id
      t.timestamps
    end
  end

  def self.down
    drop_table :help_attachments
  end
end