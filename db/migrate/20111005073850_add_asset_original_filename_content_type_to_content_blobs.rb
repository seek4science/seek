class AddAssetOriginalFilenameContentTypeToContentBlobs < ActiveRecord::Migration
  def self.up
    add_column :content_blobs, :original_filename, :string
    add_column :content_blobs, :content_type, :string
    add_column :content_blobs, :asset_id, :integer
    add_column :content_blobs, :asset_type, :string
    add_column :content_blobs, :asset_version, :integer
  end

  def self.down
    remove_column :content_blobs, :original_filename, :content_type, :asset_id, :asset_type, :asset_version
  end
end
