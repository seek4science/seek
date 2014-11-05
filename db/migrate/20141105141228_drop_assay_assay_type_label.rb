class DropAssayAssayTypeLabel < ActiveRecord::Migration
  def up
    remove_column :assays,:assay_type_label
  end

  def down
    add_column :assays,:assay_type_label,:string
  end
end
