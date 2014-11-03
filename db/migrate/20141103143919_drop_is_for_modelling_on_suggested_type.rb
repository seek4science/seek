class DropIsForModellingOnSuggestedType < ActiveRecord::Migration
  def up
    remove_column :suggested_assay_types,:is_for_modelling
  end

  def down
    add_column :suggested_assay_types, :is_for_modelling, :boolean
  end
end
