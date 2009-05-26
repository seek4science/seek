class LargerBinaryContentBlob < ActiveRecord::Migration
  def self.up
    change_column :content_blobs,:data,:binary,:limit=>40.megabytes
  end

  def self.down
    change_column :content_blobs,:data,:binary,:limit=>2.megabytes
  end
end
