class AddUrlToContentBlobs < ActiveRecord::Migration
  
  def self.up
    add_column :content_blobs, :url, :string  
  end

  def self.down
    remove_column :content_blobs, :url
  end
end
