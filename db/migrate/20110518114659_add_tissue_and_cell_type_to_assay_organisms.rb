class AddTissueAndCellTypeToAssayOrganisms < ActiveRecord::Migration
  def self.up
    add_column :assay_organisms,:tissue_and_cell_type_id,:integer
  end

  def self.down
    remove_column :assay_organisms,:tissue_and_cell_type_id
  end
end
