class AddTimestampsToContentBlob < ActiveRecord::Migration
  def change
    add_timestamps(:content_blobs)
  end
end
