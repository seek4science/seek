class DropDataOldAttribute < ActiveRecord::Migration
  def up
    remove_column :content_blobs, :data_old
  end

  def down
    add_column :content_blobs, :data_old,:binary
  end

end
