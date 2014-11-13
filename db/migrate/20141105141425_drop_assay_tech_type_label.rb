class DropAssayTechTypeLabel < ActiveRecord::Migration
  def up
    remove_column :assays,:technology_type_label
  end

  def down
    add_column :assays,:technology_type_label,:string
  end
end
