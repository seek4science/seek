class AddPriorityToQueues < ActiveRecord::Migration[5.2]
  def change
    add_column :reindexing_queues, :priority, :integer, default: 0
    add_column :rdf_generation_queues, :priority, :integer, default: 0
  end
end
