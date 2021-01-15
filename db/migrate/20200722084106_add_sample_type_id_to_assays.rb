class AddSampleTypeIdToAssays < ActiveRecord::Migration[5.2]
  def change
    add_column :assays, :sample_type_id, :integer
    add_index  :assays, :sample_type_id
  end
end
