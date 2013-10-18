class DropAttachments < ActiveRecord::Migration
  def self.up
    remove_index :attachments, :parent_id
    remove_index :attachments, [:attachable_id, :attachable_type]
    drop_table :attachments
  end

  def self.down
    create_table :attachments do |t|
      t.integer :size, :height, :width, :parent_id, :attachable_id, :position
      t.string :content_type, :filename, :thumbnail, :attachable_type
      t.string  :data_url
      t.string :original_filename
      t.timestamps
    end
    add_index :attachments, :parent_id
    add_index :attachments, [:attachable_id, :attachable_type]
  end
end
