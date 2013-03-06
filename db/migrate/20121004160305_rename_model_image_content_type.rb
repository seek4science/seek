class RenameModelImageContentType < ActiveRecord::Migration
  def self.up
    rename_column :model_images, :original_content_type, :content_type
  end

  def self.down
    rename_column :model_images, :content_type, :original_content_type
  end
end
