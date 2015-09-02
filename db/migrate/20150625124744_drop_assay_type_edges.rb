class DropAssayTypeEdges < ActiveRecord::Migration

  def up
    drop_table :assay_types_edges
    drop_table :technology_types_edges
  end

  def down
    create_table :assay_types_edges, :id => false, :force => true do |t|
      t.integer :parent_id
      t.integer :child_id
    end

    create_table :technology_types_edges, :id => false, :force => true do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end

end
