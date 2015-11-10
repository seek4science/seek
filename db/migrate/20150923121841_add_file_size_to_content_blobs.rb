class AddFileSizeToContentBlobs < ActiveRecord::Migration
  def change
    change_table :content_blobs do |t|
      t.integer :file_size, limit: 8
    end
  end
end
