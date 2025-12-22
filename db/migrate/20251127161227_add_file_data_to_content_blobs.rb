class AddFileDataToContentBlobs < ActiveRecord::Migration[7.2]
  def change
    add_column :content_blobs, :file_data, :text
  end
end
