class AddParentIdToSuggestedTypes < ActiveRecord::Migration
  def change
    add_column :suggested_assay_types,:parent_id,:integer
    add_column :suggested_technology_types,:parent_id,:integer
  end
end
