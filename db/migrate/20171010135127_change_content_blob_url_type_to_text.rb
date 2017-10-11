class ChangeContentBlobUrlTypeToText < ActiveRecord::Migration
  def up
    change_column :content_blobs, :url, :text
  end

  def down
    change_column :content_blobs, :url, :string
  end
end
