class AddUuidToContentBlob < ActiveRecord::Migration
  def self.up
    add_column :content_blobs, :uuid, :string
  end

  def self.down
    remove_column :content_blobs,:uuid
  end
end
