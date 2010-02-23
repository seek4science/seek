class AddMd5sumToContentBlobs < ActiveRecord::Migration
  
  def self.up
    add_column :content_blobs, :md5sum, :string              
  end

  def self.down
    remove_column :content_blobs, :md5sum
  end
  
end
