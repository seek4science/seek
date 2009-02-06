class CreateContentBlobs < ActiveRecord::Migration
  def self.up
    create_table :content_blobs do |t|
      t.column :data, :binary, :limit => 1073741824
    end
  end

  def self.down
    drop_table :content_blobs
  end
end
