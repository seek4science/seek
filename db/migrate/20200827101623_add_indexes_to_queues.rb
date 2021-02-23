class AddIndexesToQueues < ActiveRecord::Migration[5.2]
  def change
    add_index :auth_lookup_update_queues, [:item_id, :item_type]
    add_index :reindexing_queues, [:item_id, :item_type]
    add_index :rdf_generation_queues, [:item_id, :item_type]
  end
end
