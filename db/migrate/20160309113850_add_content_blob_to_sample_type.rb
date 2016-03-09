class AddContentBlobToSampleType < ActiveRecord::Migration
  def change
    add_column :sample_types, :content_blob_id, :integer
  end
end
