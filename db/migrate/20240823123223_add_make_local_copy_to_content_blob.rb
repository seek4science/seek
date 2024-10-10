class AddMakeLocalCopyToContentBlob < ActiveRecord::Migration[6.1]
  def change
    add_column :content_blobs, :make_local_copy, :boolean, default: false
  end
end
