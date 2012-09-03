class AddExternalLinkToContentBlob < ActiveRecord::Migration
  def self.up
    add_column :content_blobs, :external_link, :boolean
  end

  def self.down
    remove_column :content_blobs, :external_link
  end
end
