class AddSha1ToContentBlob < ActiveRecord::Migration
  def change
    add_column :content_blobs, :sha1sum, :string
  end
end
