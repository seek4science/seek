class AddAssayIdToGalaxyExecution < ActiveRecord::Migration[5.2]
  def change
    add_column :galaxy_execution_queue_items, :assay_id, :integer
  end
end
