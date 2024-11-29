class AddDeletedFlagToContentBlob < ActiveRecord::Migration[6.1]
  def change
    add_column :content_blobs, :deleted, :boolean, default: false
  end
end
