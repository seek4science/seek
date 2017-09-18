class AddClassTypeToAssays < ActiveRecord::Migration
  def change
    add_column :assays, :class_type, :string
    add_index :assays, [:class_type, :id], name: 'assay_by_class_type_and_PK'
  end
end
