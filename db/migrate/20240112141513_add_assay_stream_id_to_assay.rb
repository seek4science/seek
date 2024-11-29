class AddAssayStreamIdToAssay < ActiveRecord::Migration[6.1]
  def change
    add_column :assays, :assay_stream_id, :integer
    add_index :assays, :assay_stream_id
  end
end
