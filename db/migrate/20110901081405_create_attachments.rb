class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.integer     :size, :height, :width, :parent_id, :attachable_id, :position
      t.string      :content_type, :filename, :thumbnail, :attachable_type
      t.timestamps
      t.timestamps
    end
    add_index :attachments, :parent_id
    add_index :attachments, [:attachable_id, :attachable_type]
  end

  def self.down
    drop_table :attachments
  end
end
