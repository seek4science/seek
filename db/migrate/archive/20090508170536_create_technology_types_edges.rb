class CreateTechnologyTypesEdges < ActiveRecord::Migration
  
  def self.up
    create_table :technology_types_edges,:id=>false do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end

  def self.down
    drop_table :technology_types_edges
  end
end
