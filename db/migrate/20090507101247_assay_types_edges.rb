class AssayTypesEdges < ActiveRecord::Migration
  def self.up
    create_table :assay_types_edges,:id=>false do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end

  def self.down
    drop_table :assay_types_edges
  end
end
