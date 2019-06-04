class AddExecutionIdToGalaxyItem < ActiveRecord::Migration[5.2]
  def change
    add_column :galaxy_execution_queue_items, :execution_id, :string
  end
end
