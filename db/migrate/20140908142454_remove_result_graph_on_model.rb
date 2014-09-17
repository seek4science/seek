class RemoveResultGraphOnModel < ActiveRecord::Migration
  def up
    remove_column :models, :result_graph
    remove_column :model_versions, :result_graph
  end

  def down
    add_column :models, :result_graph, :text
    add_column :model_versions, :result_graph, :text
  end
end
