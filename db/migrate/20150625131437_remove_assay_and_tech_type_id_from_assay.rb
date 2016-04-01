class RemoveAssayAndTechTypeIdFromAssay < ActiveRecord::Migration
  def up
    if column_exists? :assays, :assay_type_id
      remove_column :assays,:assay_type_id
    end
    if column_exists? :assays, :technology_type_id
      remove_column :assays, :technology_type_id
    end
  end

  def down
    add_column :assays, :assay_type_id, :integer
    add_column :assays, :technology_type_id, :integer
  end
end
