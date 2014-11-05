class AddSuggestedAssayTypeToAssay < ActiveRecord::Migration
  def change
    add_column :assays, :suggested_assay_type_id,:integer
  end
end
