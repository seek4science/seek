class AddSourcePathToAssayTypesAndTechnologyTypes < ActiveRecord::Migration
  def change
    add_column :assay_types, :source_path, :string, :default=> nil
    add_column :technology_types, :source_path, :string, :default=> nil
  end
end
