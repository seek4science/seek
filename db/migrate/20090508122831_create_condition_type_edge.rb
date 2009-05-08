class CreateConditionTypeEdge < ActiveRecord::Migration
  def self.up
    create_table :condition_types_edges,:id=>false do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end

  def self.down
    drop_table :condition_types_edges
  end
end
