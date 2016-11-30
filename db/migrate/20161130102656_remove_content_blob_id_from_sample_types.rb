class RemoveContentBlobIdFromSampleTypes < ActiveRecord::Migration
  def up
    remove_column :sample_types, :content_blob_id
  end

  def down
    add_column :sample_types, :content_blob_id, :integer
  end
end
