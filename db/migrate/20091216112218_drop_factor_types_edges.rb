class DropFactorTypesEdges < ActiveRecord::Migration
  def self.up
    drop_table :factor_types_edges
  end

  def self.down
    create_table :factor_types_edges, :id => false, :force => true do |t|
      t.integer "parent_id"
      t.integer "child_id"
    end
  end
end
