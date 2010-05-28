class RenameDeprecatedContentBlobData < ActiveRecord::Migration
  def self.up
    rename_column(:content_blobs, :data, :data_old)
  end

  def self.down
    rename_column(:content_blobs, :data_old, :data)
  end
end
